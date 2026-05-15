# PLAN — Boilerplate Rails 8 SaaS

Decisões confirmadas com o usuário em 2026-05-14:

- **Nome inicial do app:** `BoilerplateSaas` / `boilerplate_saas` (renomeado depois via `bin/rename-app`)
- **Stack:** Ruby 3.4.1 + Rails 8.1.3, SQLite × 4 (primary/queue/cache/cable)
- **Campos BR:** mantidos no boilerplate (CPF, phone BR, country=BR, TZ America/Fortaleza)
- **Execução:** pausar em cada marco para revisão. Após cada fase, eu reporto resultado + `bin/ci` e espero OK.

## Fases

### Fase 0 — Bootstrap
- [ ] Confirmar Rails 8.1.3 instalável (`gem install rails -v 8.1.3 --no-document`)
- [ ] `rails new boilerplate_saas -d sqlite3 --css=tailwind --skip-bundle` na pasta atual (já existe vazia)
- [ ] Rodar bundle install, ajustar `.ruby-version`, `Gemfile.lock` consistente
- [ ] Configurar Rails 8 4-databases SQLite (primary + queue + cache + cable) explicitamente em `database.yml`
- [ ] Locale pt-BR (default) + en (fallback), TZ America/Fortaleza
- [ ] `bin/rails db:prepare` verde
- [ ] Commit interno mental: "rails new working"

**Pausa para revisão.**

### Fase 1 — Multi-tenancy core (sem auth ainda)
- [ ] Migrations: `accounts`, `users`, `account_users`, `addresses`
- [ ] Models: `User`, `Account`, `AccountUser`, `Address`
- [ ] `Current` attributes (`user`, `account`, `request_id`)
- [ ] Validações BR (CPF formato, phone formato)
- [ ] Enums (`AccountUser#role`, `Account#billing_type`)
- [ ] Pundit base: `ApplicationPolicy` com `policy_scope` por `Current.account`
- [ ] Specs/tests dos models (Minitest, fixtures mínimas)

**Pausa para revisão.**

### Fase 2 — Autenticação
- [ ] `bin/rails generate authentication` (gerador nativo Rails 8)
- [ ] Estender com `name` no User
- [ ] Signup transacional: User + Account(name=user.name) + AccountUser(owner)
- [ ] Login / logout / esqueci senha / redefinir senha (views Tailwind pt-BR)
- [ ] `AccountsController#switch` + `session[:current_account_id]`
- [ ] Pundit `verify_authorized` / `verify_policy_scoped` no ApplicationController
- [ ] Skip Pundit em auth/health/webhook
- [ ] Testes: signup, login, logout, reset, switch, multi-tenancy isolation

**Pausa para revisão.**

### Fase 3 — Observabilidade (3 camadas)
- [ ] Lograge JSON com `request_id`, `user_id`, `account_id`, `ip`, `params` em prod/staging
- [ ] `query_log_tags` ativado
- [ ] AuditLog: migration + model + `Auditable` concern + `audit!` helper no ApplicationController
- [ ] Eventos auto: user.signup/login/login_failed/logout/password_*, account.created, account_user.role_changed
- [ ] RequestLog: migration + model + `RequestLogging` concern + categorização por rota
- [ ] `RequestLogCreateJob` (Solid Queue) para não bloquear request
- [ ] `PurgeOldRequestLogsJob` + `config/recurring.yml` (3am diário, 60d retenção)
- [ ] Healthcheck `/up` NÃO loga em RequestLog (categoria nil)
- [ ] Filter parameters para senha/token/cpf/etc.
- [ ] Testes: AuditLog em login, RequestLog em /sessions, RequestLog em /up (nenhum), purge job

**Pausa para revisão.**

### Fase 4 — Stripe billing
- [ ] `gem "stripe"` + initializer (api_version pinned)
- [ ] Migration + model `Subscription` (com `processed_stripe_events` para idempotência)
- [ ] Controllers: `Billing::CheckoutsController`, `Billing::PortalController`, `Webhooks::StripeController`
- [ ] Services: `Billing::CreateCheckoutSession`, `Billing::CreatePortalSession`, `Billing::StripeEventHandler`
- [ ] Eventos: subscription.created/updated/deleted, invoice.payment_failed, checkout.session.completed
- [ ] Webhook: assinatura validada, sempre 200, RequestLog category=webhook
- [ ] `Account#start_checkout!`, `#open_billing_portal!`
- [ ] Rack::Attack: 10 webhook/min/IP
- [ ] Fixtures em `test/fixtures/stripe/*.json`
- [ ] Testes: assinatura inválida → 400, created → Subscription + AuditLog, updated → atualiza, idempotência

**Pausa para revisão.**

### Fase 5 — Hardening, scripts, CI, docs
- [ ] Rack::Attack completo (login/signup/webhook)
- [ ] `bin/rename-app` script bash (valida PascalCase, substitui module + banco + deploy.yml + package.json + README + Procfile.dev + bin/dev)
- [ ] `bin/setup`, `bin/dev`, `bin/ci`
- [ ] `config/ci.rb` (rubocop, brakeman, bundler-audit, importmap audit, tests)
- [ ] `config/deploy.yml` (Kamal 2 base, sem secrets)
- [ ] Dockerfile production (multi-stage, defaults Rails 8 + thruster)
- [ ] `.rubocop.yml` (rails-omakase)
- [ ] README.md em pt-BR (10 seções do prompt)
- [ ] CLAUDE.md (convenções, multi-tenancy, RequestLog vs AuditLog)

**Pausa para revisão.**

### Fase 6 — Validação final
- [ ] `bin/ci` verde
- [ ] `bin/rails server` sobe; `curl /up` → 200; `curl /` → 302 para `/session/new`
- [ ] `bin/rails routes` output
- [ ] Log JSON de uma request em production-like (`RAILS_ENV=production SECRET_KEY_BASE=test`)
- [ ] Fixture de webhook Stripe processada corretamente
- [ ] Lista completa de arquivos criados/modificados

## Convenções durante a execução

- Locale: textos visíveis em `config/locales/pt-BR.yml`. Não hardcoded.
- Models tenant-scoped: sempre `belongs_to :account` + index em `account_id`.
- Controllers: `authorize` em ação que muda estado, `policy_scope` em `index`/`show` quando aplicável.
- Tailwind: classes utilitárias direto na view, sem CSS custom.
- Sem comentários óbvios no código (políticas, helpers, etc). Comentários só onde o "porquê" não é evidente.
- Sem gems "por garantia": só o que está em uso.
