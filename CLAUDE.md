# CLAUDE.md — boilerplate-saas

Para futuros prompts no Claude Code rodando neste projeto.

## Stack

- Ruby 3.4.1 / Rails 8.1.3
- SQLite × 4 (primary / queue / cache / cable) em todos os envs (dev, test, prod)
- Hotwire + Importmap + Propshaft + Tailwind v4
- Solid Queue (jobs), Solid Cache (cache), Solid Cable (cable)
- Auth nativa Rails 8 + Pundit
- Stripe billing (checkout + portal + webhook idempotente)
- Kamal 2 + Thruster

**Não usar:** Devise · Sidekiq · Redis · Webpacker · Sprockets · esbuild · bun · PostgreSQL.

## Multi-tenancy é central

- `Account` é o tenant. `User` tem N `Accounts` via `AccountUser` (roles: `owner`, `admin`, `member`).
- Tudo escopado por `Current.account`. Toda nova model tenant-scoped precisa de `belongs_to :account` + índice em `account_id`.
- `ApplicationPolicy::Scope#resolve` já filtra automaticamente por `Current.account.id` quando a tabela tem essa coluna.
- `ApplicationController` chama `verify_authorized` / `verify_policy_scoped` em todas as ações exceto nos controllers da lista `SKIP_PUNDIT_CONTROLLERS` (`sessions`, `passwords`, `registrations`, `home`, `rails/health`, `webhooks`, `billing`).

## Convenções

- **RESTful**: ações canônicas só. Custom action precisa de justificativa.
- **Hotwire-first**: Turbo Streams antes de criar API. Sem rotas `respond_to :json` a menos que pedido.
- **Tailwind only**: classes utilitárias direto na view. Sem CSS custom em `app/assets/stylesheets/*`.
- **Textos visíveis sempre via `I18n.t`** em `config/locales/pt-BR.yml`. Nenhuma string em português hardcoded em view ou controller.
- **Comentários só onde o "porquê" não é evidente**. Nada de comentar o quê faz código auto-evidente.

## Como adicionar uma feature tenant-scoped

1. Migration: tabela com `account:references` e `t.references :account, foreign_key: true`.
2. Model: `belongs_to :account` + validações.
3. Policy: estender `ApplicationPolicy`; geralmente nada a fazer se as ações default servem.
4. Controller: `policy_scope(Model)` em `index`/`show`, `authorize @record` em `create`/`update`/`destroy`.
5. View: Tailwind + I18n.
6. Teste: model (validações + escopos), controller (autorização + sucesso/falha), e integração se houver fluxo cross-controller.
7. AuditLog: `audit!("dominio.evento", auditable: @record, ...)` se for evento relevante de negócio/segurança.

## RequestLog vs AuditLog (não confundir)

- **AuditLog** (`app/models/audit_log.rb`) — eventos de **negócio ou segurança**. Compliance, auditoria, "quem fez o quê". Manual, via helper `audit!` em controller.
- **RequestLog** (`app/models/request_log.rb`) — diagnóstico de **HTTP** para suporte ("o que o usuário X fez nas últimas 24h"). Automático via `RequestLogging` concern para categorias específicas (`auth`, `webhook`, `payment`, `admin`, `api`). Retenção 60 dias.
- **Lograge** — apenas em prod/staging, formato JSON para agregador externo. Não persistido.

## Segurança

- **Nunca logar PII / tokens**: `filter_parameters` está em `config/initializers/filter_parameter_logging.rb`.
- **Rack::Attack**: 5 logins / 5min / IP, 3 signups / hora / IP, 10 passwords / hora / IP, 10 webhook Stripe / min / IP.
- **Stripe webhook**: sempre valida assinatura (`Stripe::Webhook.construct_event`). Falhas de assinatura → 400. Falhas de processamento → 200 (Stripe re-tenta com base em event.id; nós dedup via `processed_stripe_events`).
- **Pundit**: `verify_authorized` lança em qualquer ação não isenta que esqueceu de chamar `authorize` / `policy_scope`.

## Comandos úteis

```
bin/dev                          # servidor de desenvolvimento (Tailwind watch + Rails)
bin/rails test                   # roda toda a suite
bin/ci                           # rubocop + brakeman + bundler-audit + importmap audit + tests
bin/rails credentials:edit       # editar credentials (Stripe, etc.)
bin/rails routes | grep auth     # ver rotas
bin/rename-app NovoNome          # renomeia o app
kamal deploy                     # deploy
```
