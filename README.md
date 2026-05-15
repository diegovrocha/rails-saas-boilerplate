# Boilerplate SaaS — Rails 8 multi-tenant

Starter kit Rails 8.1 / Ruby 3.4 para SaaS multi-tenant. Após `git clone` + `bin/rename-app` + credenciais Stripe, sobe pronto com autenticação, multi-tenancy, audit log, request log, billing Stripe e Kamal pré-configurado.

Este repositório **não é um SaaS pronto** — é a fundação comum sobre a qual projetos específicos são construídos.

## Como usar

```bash
git clone <repo> meu-novo-saas
cd meu-novo-saas
bin/rename-app MeuNovoSaas
bin/rails credentials:edit       # configurar Stripe (ver seção Stripe)
bin/dev                          # http://localhost:3000
```

## Stack

| Camada            | Tecnologia                                                |
| ----------------- | --------------------------------------------------------- |
| Linguagem         | Ruby **3.4.1**                                            |
| Framework         | Rails **8.1.3**                                           |
| Banco             | SQLite × 4 (primary / queue / cache / cable)              |
| Frontend          | Hotwire (Turbo + Stimulus) + Importmap + Propshaft        |
| CSS               | Tailwind CSS v4 via `tailwindcss-rails`                   |
| Autenticação      | `bin/rails generate authentication` (nativo Rails 8)      |
| Autorização       | Pundit                                                    |
| Background jobs   | Solid Queue (em SQLite, dedicado)                         |
| Cache             | Solid Cache (em SQLite, dedicado)                         |
| Action Cable      | Solid Cable (em SQLite, dedicado)                         |
| Observability     | Lograge (JSON) + `AuditLog` + `RequestLog`                |
| Billing           | Stripe (checkout + portal + webhook idempotente)          |
| Rate limit        | Rack::Attack                                              |
| Deploy            | Kamal 2 + Thruster                                        |
| Testes            | Minitest                                                  |
| Lint / Security   | rubocop-rails-omakase + brakeman + bundler-audit          |
| Locale            | pt-BR (default) + en (fallback)                           |
| Timezone          | America/Fortaleza                                         |

## Multi-tenancy

**Account** é o tenant. **User** pertence a uma ou mais Accounts via **AccountUser** com role (`owner`, `admin`, `member`).

```
User -- AccountUser -- Account
                          |--- Address (has_one)
                          |--- Subscription (has_one)
```

- `Current.user`, `Current.account` e `Current.request_id` ficam acessíveis no controller, model e job.
- A account ativa é escolhida pela `session[:current_account_id]`; se vazia, cai na primeira account do usuário.
- Endpoint `POST /accounts/:id/switch` troca a account ativa.

### Adicionar um modelo tenant-scoped

```bash
bin/rails generate model Project name:string account:references
```

```ruby
class Project < ApplicationRecord
  belongs_to :account
end

class ProjectPolicy < ApplicationPolicy
  # ApplicationPolicy::Scope já filtra automaticamente por Current.account
  # quando a tabela tem account_id.
end

class ProjectsController < ApplicationController
  def index
    @projects = policy_scope(Project)
  end

  def show
    @project = policy_scope(Project).find(params[:id])
    authorize @project
  end
end
```

`ApplicationPolicy::Scope#resolve` aplica `where(account_id: Current.account.id)` automaticamente em qualquer model que tenha essa coluna. `ApplicationController` chama `verify_authorized` (e `verify_policy_scoped` em `index`) após cada ação, exceto em controllers explicitamente isentos (`sessions`, `passwords`, `registrations`, `home`, `rails/health`, `webhooks`, `billing`).

## Autenticação

Construída em cima do gerador nativo `bin/rails generate authentication`.

| Rota                          | Controller              |
| ----------------------------- | ----------------------- |
| `GET  /session/new`           | `SessionsController#new`     |
| `POST /session`               | `SessionsController#create`  |
| `DELETE /session`             | `SessionsController#destroy` |
| `GET  /registration/new`      | `RegistrationsController#new` |
| `POST /registration`          | `RegistrationsController#create` (transacional) |
| `GET  /passwords/new`         | `PasswordsController#new`    |
| `POST /passwords`             | `PasswordsController#create` |
| `GET  /passwords/:token/edit` | `PasswordsController#edit`   |
| `PATCH /passwords/:token`     | `PasswordsController#update` |

Signup cria, numa única transação: `User` + `Account` (nome = `user.name`) + `AccountUser(role: owner)`.

### Adicionar um campo ao User

```bash
bin/rails generate migration AddPhoneToUsers phone:string
```

```ruby
# app/models/user.rb
validates :phone, format: { with: /\A\d{10,11}\z/ }, allow_blank: true
```

Atualize o `params.expect` em `RegistrationsController` para aceitar o novo campo e a view `registrations/new.html.erb`.

## Logs — três camadas, intenções distintas

| Camada      | Onde vai                                  | Para quê                                        |
| ----------- | ----------------------------------------- | ----------------------------------------------- |
| **Lograge** | STDOUT em JSON (em prod / staging)        | Agregador externo (Datadog, Logtail, Loki…)    |
| **AuditLog**  | Tabela `audit_logs`                     | Compliance, "quem fez o quê e quando"          |
| **RequestLog**| Tabela `request_logs` (retenção 60 dias) | Suporte: "o que o usuário X fez nas últimas 24h" |

### Quando usar cada um

- Eventos de **negócio ou segurança** (login bem-sucedido, role alterada, assinatura criada): **AuditLog** via `audit!("evento", ...)` no controller.
- **Diagnóstico de HTTP** (qual rota o usuário visitou, status, latência): **RequestLog** — automático via `RequestLogging` concern, só para categorias específicas (`auth`, `webhook`, `payment`, `admin`, `api`).
- Métricas de prod e observability externa: **Lograge** — automático, formato JSON.

`/up` (healthcheck) e o `home_controller` NÃO geram `RequestLog` (categoria nil — evita poluir o banco com page views triviais).

### Retenção de RequestLog

`PurgeOldRequestLogsJob` roda diariamente às 3am (ver [config/recurring.yml](config/recurring.yml)) e apaga registros > 60 dias em batches. Para mudar a janela:

```ruby
PurgeOldRequestLogsJob.new.perform(retention: 30.days)
```

## Stripe — checklist

1. **Criar produto e preço no dashboard** Stripe (modo test):
   <https://dashboard.stripe.com/test/products>
2. Anotar `Secret key`, `Publishable key` e o `price_id` (algo como `price_1Nx...`).
3. **Configurar credentials**:
   ```bash
   bin/rails credentials:edit
   ```
   Colar:
   ```yaml
   stripe:
     secret_key:        sk_test_...
     publishable_key:   pk_test_...
     webhook_secret:    whsec_...
     default_price_id:  price_...
   ```
4. **Configurar endpoint de webhook no Stripe**:
   - URL: `https://seu-app.com/webhooks/stripe`
   - Eventos: `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`, `checkout.session.completed`
   - Copiar o `Signing secret` (começa com `whsec_`) para o `webhook_secret` do credentials.
5. **Testar em desenvolvimento**:
   ```bash
   stripe listen --forward-to localhost:3000/webhooks/stripe
   stripe trigger customer.subscription.created
   ```
6. Usar no app:
   ```ruby
   url = current_account.start_checkout!(success_url: ..., cancel_url: ...)
   redirect_to url, allow_other_host: true
   ```

A integração é **idempotente** — eventos duplicados são detectados via tabela `processed_stripe_events`.

## Deploy (Kamal)

```bash
# Primeira vez
kamal setup       # configura servidor, instala docker, faz primeiro deploy

# Subsequentes
kamal deploy

# Logs
kamal logs -f
```

`config/deploy.yml` é template — edite com seu IP, registry e domínio. Secrets vivem em `.kamal/secrets` (que carrega de `config/master.key` e ENV).

## Testes

```bash
bin/rails test                  # tudo
bin/rails test test/models      # só models
bin/ci                          # CI completo (rubocop + brakeman + bundler-audit + tests)
```

A suite cobre: signup transacional, login (sucesso/falha), logout, reset de senha, switch de account, isolamento multi-tenant (Pundit), políticas de AccountUser (proteção de último owner), webhook Stripe (assinatura inválida → 400, idempotência), retenção do RequestLog, e log auditável de eventos de auth.

## Customização

| O que                       | Onde                                                   |
| --------------------------- | ------------------------------------------------------ |
| Cor primária do Tailwind    | substituir `bg-blue-600` / `text-blue-600` nas views   |
| Locale default              | `config/application.rb`                                |
| Timezone                    | `config/application.rb`                                |
| Remover CPF/phone BR        | `app/models/account.rb` (validations) + migration      |
| Campos em users             | gerar migration; ajustar `RegistrationsController#user_params` + view `registrations/new` |
| Adicionar evento auditável  | `audit!("dominio.evento", auditable: record, key: val)` em controller |
| Categoria custom de RequestLog | `app/controllers/concerns/request_logging.rb` (`CATEGORY_PREFIXES`) |

## Restrições / não-objetivos

- **Não tem painel admin** — cada projeto adiciona.
- **Convite por email** é stub (`AccountUsersController#create` requer user já cadastrado). Fluxo completo de convite por email fica para projetos específicos.
- Não usa Devise, Sidekiq, Webpacker, Sprockets, esbuild, bun ou PostgreSQL — por escolha.
