# Terraform Associate (004) — Hands-On Lab Guide 

Happy to announce that I recently gave Hashicorp's Terraform Associate (004) Certification Exam and I cracked it. 

If you have worked with Terraform, its pretty simple. If not, this guide can help you. 

A complete, runnable set of exercises mapped to every objective on the **HashiCorp Certified: Terraform Associate (004)** exam. Designed for the last few days before the exam.

> **Why these labs cost nothing:** 

> Labs 1–12 use the `random`, `local`, `null`, `tls`, and `time` providers. They require **no cloud account and no credentials** but exercise every core Terraform mechanic the exam tests. Labs touching backends/HCP and the portfolio project use Docker (also free and local).

## How to use this guide

1. Install Terraform (Lab 0).
2. Work each lab in its own folder (examples and solutions given already). Type the code by hand — do not copy-paste blindly; muscle memory matters for the exam.
3. For each lab, run the **commands**, read the **What to observe** notes, then read the **Exam tips** (these are the trap areas).
4. The exam is ~57 multiple-choice/multiple-select questions in 60 minutes, provider-agnostic. It tests *understanding of Terraform itself*, not AWS/Azure specifics.

### Objective coverage map

| Domain | Objectives | Labs |
|---|---|---|
| 1. IaC with Terraform | 1a–1c | Lab 1 |
| 2. Terraform fundamentals | 2a–2d | Labs 2, 3 |
| 3. Core workflow | 3a–3g | Lab 4 |
| 4. Configuration | 4a–4h | Labs 5–11 |
| 5. Modules | 5a–5d | Lab 12 |
| 6. State management | 6a–6d | Lab 13 |
| 7. Maintain infrastructure | 7a–7c | Lab 14 |
| 8. HCP Terraform | 8a–8d | Lab 15 |
| Meta-arguments & misc (tested throughout) | — | Lab 16 |

---

## Lab 0 — Setup & sanity check

**Install Terraform** (pick one):
- macOS: `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
- Windows: `choco install terraform` or download the binary from releases.hashicorp.com
- Linux: download the zip, unzip, move `terraform` onto your `$PATH`

**Verify:**
```bash
terraform version          # confirms install + shows provider versions later
terraform -install-autocomplete   # optional: tab-completion
terraform -help            # browse available subcommands
```

**What to observe:** `terraform version` reports the CLI version and (after an init) the versions of installed providers. The exam expects you to know the binary is a single statically-linked executable — there is nothing else to install for core Terraform.

---

## Lab 1 — Infrastructure as Code concepts (Objectives 1a, 1b, 1c)

This domain is conceptual but anchor it with a first real config.

**Folder:** `lab01-iac/main.tf`
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Infrastructure as Code means this file is declared, versioned, and reproducible.\n"
}
```

**Commands:**
```bash
terraform init
terraform apply -auto-approve
cat hello.txt
terraform destroy -auto-approve   # the file disappears — Terraform owns its lifecycle
```

**Concepts to lock in for the exam:**
- **IaC** = managing infrastructure through machine-readable config files instead of manual processes/clicking. Benefits: versioned (git), repeatable, reviewable, automatable, self-documenting, reduces config drift and human error.
- **Declarative vs imperative:** Terraform is **declarative** — you describe the *desired end state*, not the steps. Terraform figures out the steps.
- **Provisioning vs configuration management:** Terraform *provisions* infrastructure (creates resources). Tools like Ansible/Chef/Puppet are configuration management (configure software on existing machines). They are complementary.
- **Multi-cloud / hybrid / service-agnostic (1c):** Terraform uses **providers** to talk to *any* API — AWS, Azure, GCP, Kubernetes, GitHub, Datadog, Cloudflare, etc. One workflow, one language (HCL), many platforms. This is Terraform's key differentiator from cloud-native tools like CloudFormation (AWS-only) or ARM (Azure-only).
- Terraform is **cloud-agnostic** and **immutable-friendly** but does not force immutability.

**Exam tips:**
- "Which tool lets you provision across AWS and Azure in one workflow?" → Terraform's multi-cloud/provider model.
- Terraform Core is **open source**; HCP Terraform / Terraform Enterprise are the paid collaboration layers.

---

## Lab 2 — Providers: install, version, multiple providers (Objectives 2a, 2b, 2c)

**Folder:** `lab02-providers/main.tf`
```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"     # pessimistic constraint: >= 3.6.0, < 4.0.0
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4, < 3.0"
    }
  }
}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "local_file" "out" {
  filename = "${path.module}/petname.txt"
  content  = random_pet.name.id
}
```

**Commands:**
```bash
terraform init             # downloads providers into .terraform/, writes .terraform.lock.hcl
ls -la .terraform.lock.hcl
terraform providers        # shows the provider dependency tree
terraform apply -auto-approve
terraform init -upgrade    # re-evaluates version constraints and updates the lock file
```

**Version constraint operators (memorize these):**
- `= 1.2.0` exact
- `>= 1.2.0` minimum
- `<= 1.2.0` maximum
- `~> 1.2.0` "pessimistic" → allows 1.2.x but not 1.3.0 (rightmost component may increment)
- `~> 1.2` → allows 1.x but not 2.0
- `>= 1.2, < 2.0` range

**Provider aliases (multiple configs of one provider):**
```hcl
provider "random" {}                 # default
provider "random" { alias = "alt" }  # aliased

resource "random_pet" "a" {}
resource "random_pet" "b" {
  provider = random.alt
}
```

**What to observe:**
- The `.terraform.lock.hcl` records the *exact* provider versions and hashes. **Commit it to version control** so teammates and CI use identical providers.
- Provider source addresses have the form `[registry-host/]namespace/type`, e.g. `hashicorp/random`. Default registry host is `registry.terraform.io`.

**Exam tips:**
- `required_providers` goes inside the `terraform {}` block — not the `provider {}` block.
- Providers are **plugins**, distributed separately from Terraform core, downloaded during `init`.
- A common trick question: which file pins exact versions? → the **lock file** (`.terraform.lock.hcl`), not `required_providers` (which sets *constraints*).
- `terraform init -upgrade` is what updates the lock file to newer allowed versions.

---

## Lab 3 — How Terraform uses and manages state (Objective 2d)

State is the most heavily tested concept. Spend time here.

**Folder:** `lab03-state/main.tf`
```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

resource "random_integer" "port" {
  min = 1024
  max = 65535
}
```

**Commands:**
```bash
terraform apply -auto-approve
cat terraform.tfstate            # JSON: a real-world mapping of resources -> IDs/attributes
terraform state list             # list resources tracked in state
terraform state show random_integer.port
terraform show                   # human-readable view of state
```

**Why state exists (exam favorite):**
1. **Mapping** config to real-world resources (which `random_integer.port` = which actual value).
2. **Metadata** like resource dependencies, so Terraform can order create/destroy correctly.
3. **Performance** — caches attribute values so plans don't have to query every resource (you can `-refresh=false`).
4. **Collaboration** — shared remote state lets a team work on the same infrastructure.

**What to observe:**
- State stores **all** resource attributes, including any marked sensitive — so **state itself is sensitive** and must be protected.
- Default backend is **local**: a `terraform.tfstate` file in the working directory.

**Exam tips:**
- State is stored in **JSON**.
- Never hand-edit `terraform.tfstate`. Use `terraform state` subcommands or `moved`/`import`/`removed` blocks.
- Sensitive values appear in plaintext in state → use a backend that encrypts at rest and restrict access.

---

## Lab 4 — The core Terraform workflow (Objectives 3a–3g)

The "core workflow" = **Write → Plan → Apply**. Know every command.

**Folder:** `lab04-workflow/main.tf`
```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "local_file" "report" {
  filename = "${path.module}/report-${random_string.suffix.id}.txt"
  content  = "Generated by Terraform.\n"
}
```

**Walk the full workflow:**
```bash
terraform fmt              # 3g: rewrites files to canonical HCL style; returns names of changed files
terraform fmt -check       # CI mode: non-zero exit if formatting needed (no changes made)
terraform init             # 3b: initialize working dir, download providers, configure backend
terraform validate         # 3c: checks syntax & internal consistency (does NOT contact providers/APIs)
terraform plan             # 3d: build execution plan (+ create, ~ update, - destroy, -/+ replace)
terraform plan -out=tf.plan   # save a plan to apply exactly later
terraform apply tf.plan    # 3e: apply the saved plan with no second prompt
terraform apply            # plan + prompt for approval, then apply
terraform apply -auto-approve  # skip the interactive yes
terraform destroy          # 3f: destroy everything in state (asks to confirm)
terraform destroy -auto-approve
```

**Reading a plan (exam-critical symbols):**
- `+` create
- `-` destroy
- `~` update in place
- `-/+` destroy and recreate (replacement)
- `<=` read (data source)
- `(known after apply)` value not yet computed

**What to observe:**
- `validate` works **offline** and after `init`; it does not need credentials and does not detect drift.
- `plan` is a *preview* — it makes no changes. Saving with `-out` guarantees apply does exactly what you reviewed.
- `init` is **safe to run repeatedly** and is required after adding providers, modules, or changing the backend.

**Exam tips:**
- Order: **init → validate → plan → apply** (fmt anytime; destroy to tear down).
- `terraform validate` does NOT verify against the remote API and does NOT detect drift. `terraform plan` is what surfaces drift.
- `-target=resource.addr` lets you plan/apply a subset — use sparingly; it can cause inconsistent state.
- `terraform apply` without a saved plan runs an implicit plan first.
- `terraform refresh` is deprecated in favor of `terraform apply -refresh-only`.

---

## Lab 5 — Resources, data sources, and references (Objectives 4a, 4b)

**Folder:** `lab05-resources-data/main.tf`
```hcl
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
    time  = { source = "hashicorp/time",  version = "~> 0.11" }
  }
}

# resource block = something Terraform CREATES/MANAGES
resource "time_static" "build_time" {}

# data block = something Terraform READS (does not manage/own it)
data "local_file" "template" {
  filename = "${path.module}/template.txt"   # create this file first
}

# cross-resource reference creates an implicit dependency
resource "local_file" "rendered" {
  filename = "${path.module}/rendered.txt"
  content  = "Built at ${time_static.build_time.rfc3339}\nTemplate said: ${data.local_file.template.content}"
}
```

Create `template.txt` with any text first, then:
```bash
terraform init && terraform apply -auto-approve
cat rendered.txt
```

**Reference syntax:**
- Resource attribute: `<TYPE>.<NAME>.<ATTR>` → `time_static.build_time.rfc3339`
- Data source: `data.<TYPE>.<NAME>.<ATTR>` → `data.local_file.template.content`
- Module output: `module.<NAME>.<OUTPUT>`
- Input variable: `var.<NAME>`
- Local value: `local.<NAME>`
- Path: `path.module`, `path.root`, `path.cwd`

**Exam tips:**
- **`resource`** = managed (created, updated, destroyed by Terraform). **`data`** = read-only lookup of existing/external info.
- Data sources are read during **plan** (or refresh); they have `<=` in plan output.
- Referencing one resource's attribute inside another creates an **implicit dependency** — Terraform orders operations automatically from these references (see Lab 9).

---

## Lab 6 — Variables and outputs (Objective 4c)

**Folder:** `lab06-vars-outputs/`

`variables.tf`:
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "db_password" {
  type      = string
  sensitive = true            # hides value in plan/apply output
  default   = "changeme"
}
```

`main.tf`:
```hcl
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

resource "local_file" "config" {
  filename = "${path.module}/${var.environment}.conf"
  content  = "count=${var.instance_count}\nlogging=${var.enable_logging}\n"
}
```

`outputs.tf`:
```hcl
output "config_path" {
  value       = local_file.config.filename
  description = "Path to the generated config"
}

output "password" {
  value     = var.db_password
  sensitive = true            # required, else apply errors when sourcing from a sensitive value
}
```

**Ways to set variables (and their precedence, low → high):**
1. Environment variables: `export TF_VAR_environment=prod`
2. `terraform.tfvars` (auto-loaded)
3. `*.auto.tfvars` (auto-loaded, alphabetical)
4. `-var-file=custom.tfvars` (command line)
5. `-var="environment=prod"` (command line) — **highest priority**

**Commands:**
```bash
terraform apply -auto-approve                          # uses defaults
terraform apply -var="environment=staging" -auto-approve
TF_VAR_environment=qa terraform apply -auto-approve
terraform output                 # show all outputs
terraform output config_path     # one output
terraform output -json           # machine-readable
terraform output password        # blocked/redacted unless -json (sensitive)
```

**Exam tips (high-frequency):**
- **Precedence**: command-line `-var`/`-var-file` beats `*.auto.tfvars` beats `terraform.tfvars` beats `TF_VAR_*` env vars. The last value on the command line wins among `-var` flags.
- Files named exactly `terraform.tfvars` or ending in `.auto.tfvars` are loaded **automatically**. A file named `prod.tfvars` is **not** auto-loaded — you must pass `-var-file=prod.tfvars`.
- A variable with no default and no value supplied → Terraform **prompts interactively**.
- `sensitive = true` only suppresses display; the value is **still in plaintext in state**.
- Outputs marked `sensitive` are redacted in CLI output but visible via `terraform output -json`.

---

## Lab 7 — Complex types (Objective 4d)

**Folder:** `lab07-types/variables.tf`
```hcl
variable "tags" {                       # map of strings
  type = map(string)
  default = { team = "platform", tier = "backend" }
}

variable "zones" {                      # list of strings (ordered, duplicates allowed)
  type    = list(string)
  default = ["a", "b", "c"]
}

variable "ports" {                      # set (unordered, unique)
  type    = set(number)
  default = [80, 443, 8080]
}

variable "server" {                     # object (named attributes, mixed types)
  type = object({
    name    = string
    cpu     = number
    enabled = bool
  })
  default = { name = "web", cpu = 2, enabled = true }
}

variable "mixed" {                      # tuple (ordered, mixed types, fixed length)
  type    = tuple([string, number, bool])
  default = ["x", 1, true]
}
```

`main.tf`:
```hcl
output "first_zone"  { value = var.zones[0] }
output "team_tag"    { value = var.tags["team"] }
output "server_cpu"  { value = var.server.cpu }
output "tuple_num"   { value = var.mixed[1] }
```
```bash
terraform init && terraform apply -auto-approve
terraform console     # then type: var.zones, var.tags["team"], length(var.ports)
```

**Exam tips:**
- **Primitive types:** `string`, `number`, `bool`.
- **Collection types** (all elements same type): `list(...)`, `set(...)`, `map(...)`.
- **Structural types** (mixed): `object({...})`, `tuple([...])`.
- `list` is ordered + allows duplicates; `set` is unordered + unique; `map` is key/value.
- `any` lets Terraform infer the type.
- Access: lists/tuples by index `[0]`, maps/objects by key `["key"]` or `.attr`.

---

## Lab 8 — Expressions and functions (Objective 4e)

**Folder:** `lab08-expressions/main.tf`
```hcl
locals {
  names      = ["alice", "bob", "carol"]
  upper      = [for n in local.names : upper(n)]        # for expression -> list
  lengths    = { for n in local.names : n => length(n) } # for expression -> map
  is_prod    = terraform.workspace == "prod"
  size       = local.is_prod ? "large" : "small"        # conditional (ternary)
  joined     = join(", ", local.names)
  first_two  = slice(local.names, 0, 2)
  merged     = merge({ a = 1 }, { b = 2 })
  has_bob    = contains(local.names, "bob")
}

output "upper"     { value = local.upper }
output "lengths"   { value = local.lengths }
output "size"      { value = local.size }
output "joined"    { value = local.joined }
output "first_two" { value = local.first_two }
output "merged"    { value = local.merged }
output "has_bob"   { value = local.has_bob }
```
```bash
terraform init && terraform apply -auto-approve
terraform console
# try: max(3, 7, 2)  |  lower("HELLO")  |  cidrhost("10.0.0.0/16", 5)
#      lookup({a="x"}, "a", "default")  |  coalesce(null, "", "fallback")
#      formatdate("YYYY-MM-DD", timestamp())  |  jsonencode({k="v"})
```

**Function categories worth knowing (no need to memorize every one):**
- **String:** `format`, `join`, `split`, `replace`, `lower`, `upper`, `trimspace`, `substr`
- **Collection:** `length`, `element`, `concat`, `merge`, `lookup`, `keys`, `values`, `contains`, `flatten`, `distinct`, `slice`, `toset`, `tolist`
- **Numeric:** `min`, `max`, `abs`, `ceil`, `floor`
- **Encoding:** `jsonencode`/`jsondecode`, `base64encode`/`base64decode`, `yamlencode`
- **Filesystem:** `file`, `templatefile`, `fileexists`, `pathexpand`
- **Type/null handling:** `try`, `can`, `coalesce`, `coalescelist`, `tostring`, `tonumber`

**Exam tips:**
- `terraform console` evaluates expressions/functions against current state — great study tool.
- Terraform has a **fixed set of built-in functions**; you **cannot define custom functions** (a common trick).
- `for` expressions: `[for x in list : expr]` → list/tuple; `{for k,v in map : k => v}` → object/map.
- Conditional: `condition ? true_val : false_val`.
- Splat: `aws_instance.web[*].id` returns a list of all `id`s.

---

## Lab 9 — Resource dependencies & lifecycle (Objectives 4f) — **new emphasis in 004**

**Folder:** `lab09-dependencies/main.tf`
```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
    null   = { source = "hashicorp/null",   version = "~> 3.2" }
  }
}

resource "random_pet" "server" { length = 2 }

# IMPLICIT dependency: referencing random_pet.server.id makes local_file wait for it
resource "local_file" "name_file" {
  filename = "${path.module}/server.txt"
  content  = random_pet.server.id
}

# EXPLICIT dependency: depends_on when there is no attribute reference but order matters
resource "null_resource" "after_file" {
  depends_on = [local_file.name_file]
  triggers   = { name = random_pet.server.id }
}

# create_before_destroy: build the replacement BEFORE destroying the old one (zero-downtime)
resource "random_id" "rotating" {
  byte_length = 8
  keepers     = { version = "1" }   # change this value to force replacement
  lifecycle {
    create_before_destroy = true
  }
}
```
```bash
terraform init && terraform apply -auto-approve
terraform graph                  # prints the dependency graph (DOT format)
```

**`lifecycle` block meta-arguments (memorize all four):**
- `create_before_destroy = true` — create replacement first, then destroy old (avoids downtime).
- `prevent_destroy = true` — Terraform errors out if a plan would destroy this resource (guardrail for prod DBs).
- `ignore_changes = [tags, ...]` — ignore drift on specific attributes (or `ignore_changes = all`).
- `replace_triggered_by = [other.resource.id]` — force replacement when a referenced thing changes.

**Exam tips:**
- **Implicit** dependencies (from attribute references) are preferred. Use **`depends_on`** only when there is a hidden dependency Terraform cannot infer.
- Terraform builds a **dependency graph** and walks it to parallelize independent operations and order dependent ones.
- `create_before_destroy` reverses the default order (default is destroy-then-create).
- `prevent_destroy` does **not** prevent removing the resource from config — it blocks plans that would destroy it; remove the resource block AND the flag to delete intentionally.

---

## Lab 10 — Validate configuration with custom conditions (Objective 4g) — **new in 004**

**Folder:** `lab10-conditions/main.tf`
```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

# 1) Input variable validation
variable "instance_count" {
  type    = number
  default = 3
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "env" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of dev, staging, prod."
  }
}

resource "random_integer" "r" {
  min = 1
  max = var.instance_count

  # 2) Precondition: checked BEFORE the resource is created/updated
  lifecycle {
    precondition {
      condition     = var.instance_count >= 1
      error_message = "Need at least one instance to pick a random integer."
    }
    # 3) Postcondition: checked AFTER, validates the result
    postcondition {
      condition     = self.result <= var.instance_count
      error_message = "Result exceeded the allowed maximum."
    }
  }
}

# 4) check block: continuous, non-blocking assertions (warns, does not fail apply)
check "sanity" {
  assert {
    condition     = var.instance_count <= 10
    error_message = "instance_count is unusually high."
  }
}
```
```bash
terraform init
terraform apply -auto-approve
terraform apply -var="instance_count=99"   # see validation error
terraform apply -var="env=qa"              # see env validation error
```

**Exam tips (this is a 004 addition — expect questions):**
- **`validation`** lives inside a `variable` block; validates input.
- **`precondition`/`postcondition`** live inside a resource/data/output `lifecycle` block; assert assumptions and guarantees. `precondition` runs before; `postcondition` after (can use `self`).
- **`check`** blocks are *top-level*, run on every plan/apply, and produce **warnings without failing** — good for ongoing health assertions.
- Validation failures **halt** the run; check failures **warn** only.

---

## Lab 11 — Sensitive data & secrets (Objective 4h)

**Folder:** `lab11-sensitive/main.tf`
```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local",  version = "~> 2.5" }
  }
}

variable "api_token" {
  type      = string
  sensitive = true
}

resource "random_password" "db" {
  length  = 20
  special = true
}

resource "local_sensitive_file" "secret" {   # like local_file but content not shown in output
  filename = "${path.module}/secret.txt"
  content  = "token=${var.api_token}\ndb=${random_password.db.result}\n"
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
```
```bash
export TF_VAR_api_token="s3cr3t"
terraform init && terraform apply -auto-approve   # values show as (sensitive value)
grep -c result terraform.tfstate                  # but the password IS in state in plaintext
```

**Best practices to know for the exam:**
- Never hardcode secrets in `.tf` files (they end up in version control).
- Pass secrets via environment variables (`TF_VAR_*`), a secrets manager, or **HashiCorp Vault** (the `vault` provider can inject secrets at runtime).
- Mark variables/outputs `sensitive = true` to keep them out of CLI output and logs.
- **State always contains secrets in plaintext** → use a remote backend that encrypts at rest and lock down access (least privilege).
- Use `.gitignore` for `*.tfstate`, `*.tfvars` containing secrets, and `.terraform/`.

**Exam tips:**
- `sensitive = true` is about *display*, not *encryption*. State is still cleartext.
- Vault is HashiCorp's dedicated secrets-management tool; the Terraform Vault provider reads secrets so they aren't stored in config.

---

## Lab 12 — Modules (Objectives 5a, 5b, 5c, 5d)

A module is just a folder of `.tf` files. The **root module** is your working directory; **child modules** are called with a `module` block.

**Folder layout:**
```
lab12-modules/
├── main.tf
└── modules/
    └── filemaker/
        ├── variables.tf
        ├── main.tf
        └── outputs.tf
```

`modules/filemaker/variables.tf`:
```hcl
variable "name"    { type = string }
variable "content" { type = string, default = "hello" }
```

`modules/filemaker/main.tf`:
```hcl
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}
resource "local_file" "this" {
  filename = "${path.root}/${var.name}.txt"
  content  = var.content
}
```

`modules/filemaker/outputs.tf`:
```hcl
output "path" { value = local_file.this.filename }
```

Root `main.tf`:
```hcl
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Local module via relative path
module "alpha" {
  source  = "./modules/filemaker"
  name    = "alpha"
  content = "I came from a module."
}

module "beta" {
  source  = "./modules/filemaker"
  name    = "beta"
  content = "Modules are reusable."
}

# Registry module (versioned) — sourced from the public Terraform Registry
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"        # 5d: version pinning ONLY works with the registry/git source
# }

output "alpha_path" { value = module.alpha.path }   # 5c: consume child module output
```
```bash
terraform init       # init also installs/links modules
terraform get        # download/update modules without touching providers
terraform apply -auto-approve
```

**Module sources (5a) — where `source` can point:**
- Local paths: `./modules/x` or `../shared` (start with `./` or `../`)
- Terraform Registry: `terraform-aws-modules/vpc/aws`
- Git: `git::https://github.com/org/repo.git//subdir?ref=v1.2.0`
- GitHub shorthand: `github.com/org/repo`
- HTTP URLs, S3/GCS buckets

**Exam tips (very high frequency):**
- **Variable scope (5b):** variables are **local to the module** that declares them. A child module cannot see the parent's variables and vice versa. Data flows **in** via input arguments and **out** via `output` values only.
- A child module's outputs are accessed as `module.<NAME>.<OUTPUT>` — only **outputs** are exposed; internal resources are not directly addressable from the parent.
- **`version` (5d)** is supported for **Registry and some git** sources, **not** for local path modules.
- Use `~> 1.0` style constraints for module versions just like providers.
- After adding/changing a `module` block you must run `terraform init` (or `terraform get`) again.
- `count`/`for_each` work on `module` blocks too (e.g. `module.x[0]`, `module.x["key"]`).

---

## Lab 13 — State management & backends (Objectives 6a, 6b, 6c, 6d)

### 13a — Local backend (6a)
The default. State in `terraform.tfstate` in the working dir. You can declare it explicitly:
```hcl
terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}
```

### 13b — Remote backend + locking (6b, 6c)
Remote backends store state centrally and most support **state locking** to prevent concurrent applies from corrupting state.

Example (AWS S3 with built-in lockfile — modern approach; older exams reference DynamoDB for locking):
```hcl
terraform {
  backend "s3" {
    bucket       = "my-tf-state-bucket"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true     # S3-native locking (newer); older setups used dynamodb_table
  }
}
```
Other backends to recognize: `azurerm`, `gcs`, `consul`, `kubernetes`, `http`, and the `remote`/`cloud` block for HCP Terraform.

Changing backends:
```bash
terraform init -migrate-state    # migrate existing state to the new backend
terraform init -reconfigure      # ignore existing state, reconfigure backend fresh
```

### 13c — Drift, moved, removed, import, refresh-only (6d) — **expanded in 004**

Demo with a local resource:
```hcl
terraform {
  required_providers { local = { source = "hashicorp/local", version = "~> 2.5" } }
}
resource "local_file" "demo" {
  filename = "${path.module}/drift.txt"
  content  = "managed by terraform"
}
```
```bash
terraform apply -auto-approve
echo "changed outside terraform" > drift.txt      # introduce DRIFT manually
terraform plan                                    # plan shows ~ update to revert drift
terraform apply -refresh-only                     # 6d: update state to match reality WITHOUT changing infra
```

**`moved` block** — rename/refactor without destroy+recreate:
```hcl
moved {
  from = local_file.demo
  to   = local_file.renamed_demo
}
```

**`removed` block** — stop managing a resource without destroying it (replaces `state rm` for declarative workflows):
```hcl
removed {
  from = local_file.old
  lifecycle { destroy = false }   # keep the real resource, just drop it from state
}
```

**Import** is covered in Lab 14.

**Exam tips:**
- **State locking** prevents two people running apply simultaneously. Not all backends support it (local does via a lock file during operations; S3 via `use_lockfile`/DynamoDB; many remotes have it built in).
- `terraform force-unlock <LOCK_ID>` releases a stuck lock — use carefully.
- **Drift** = real infrastructure differs from state. `terraform plan` detects it; `apply -refresh-only` reconciles state to reality without modifying infrastructure; a normal `apply` would revert the drift back to config.
- `moved` blocks let you refactor addresses safely and are preferred over `terraform state mv`.
- `terraform refresh` is **deprecated**; use `apply -refresh-only` or `plan -refresh-only`.
- Remote state benefits: shared access, locking, encryption, no local secrets, can be consumed via `terraform_remote_state` data source.

---

## Lab 14 — Maintain infrastructure: import, inspect, log (Objectives 7a, 7b, 7c)

### 14a — Import existing infrastructure (7a)

**CLI import** (imperative):
```bash
# create a placeholder resource block first, then:
terraform import local_file.existing /absolute/path/to/file
```

**`import` block** (declarative, modern — preferred for 004):
```hcl
resource "local_file" "existing" {
  filename = "${path.module}/preexisting.txt"
  content  = "..."        # must match or be set after import
}

import {
  to = local_file.existing
  id = "/absolute/path/to/preexisting.txt"
}
```
```bash
terraform plan -generate-config-out=generated.tf   # 004: auto-generate config for imported resources
terraform apply
```

### 14b — Inspect state with the CLI (7b)
```bash
terraform state list                     # all resources in state
terraform state show <ADDR>              # one resource's attributes
terraform state mv <SRC> <DEST>          # move/rename in state
terraform state rm <ADDR>                # stop managing (does NOT destroy real resource)
terraform state pull > state.json        # download remote state to stdout
terraform state push <FILE>              # overwrite remote state (dangerous)
```

### 14c — Verbose logging (7c)
```bash
export TF_LOG=TRACE        # most verbose; also DEBUG, INFO, WARN, ERROR
export TF_LOG_PATH=./tf.log
terraform plan
unset TF_LOG TF_LOG_PATH
```

**Exam tips:**
- **`import` does not generate configuration by itself** (CLI import) — you must write the resource block. The `import` block + `-generate-config-out` can scaffold config (004 feature).
- Import only updates **state**; it never modifies real infrastructure.
- `terraform state rm` removes from state but **leaves the real resource alive** (it becomes unmanaged).
- Log levels (highest→lowest verbosity): `TRACE > DEBUG > INFO > WARN > ERROR`. Set with `TF_LOG`; redirect to a file with `TF_LOG_PATH`.

---

## Lab 15 — HCP Terraform (Objectives 8a, 8b, 8c, 8d)

HCP Terraform (formerly *Terraform Cloud*) is the managed SaaS for teams. You can do this lab free at app.terraform.io (free tier), or just learn the concepts.

**Connect the CLI to HCP Terraform (8d)** — the `cloud` block:
```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "my-app-prod"     # or: tags = ["app", "prod"]
    }
  }
}
```
```bash
terraform login              # 8d: get an API token, store in ~/.terraform.d/credentials.tfrc.json
terraform init               # migrates/links to the HCP workspace
terraform apply              # runs remotely by default (remote operations)
```

**Concepts to know (8a–8c):**
- **Workspaces (HCP)** = isolated environments each with their own state, variables, and run history. *Note:* HCP/Terraform-Cloud workspaces are **different** from CLI workspaces (Lab 16).
- **Execution modes:** *Remote* (plan/apply run on HCP's infrastructure), *Local* (HCP only stores state), *Agent* (runs on your private network via an agent).
- **VCS-driven workflow:** connect a Git repo so a push triggers a plan; a merge triggers apply.
- **Variable sets (8c):** reusable collections of variables applied across multiple workspaces.
- **Run triggers (8c):** chain workspaces so an apply in one queues a run in another.
- **Projects (8c):** group related workspaces for organization and access control.
- **Collaboration & governance (8b):**
  - **Sentinel** (policy-as-code) and **OPA** policies enforce rules before apply.
  - **Private registry** for sharing internal modules/providers.
  - **Teams & RBAC**, **cost estimation**, **drift detection**, **run tasks**, **change requests**, **audit/health**.
- **Single sign-on**, remote state storage, and a private module registry are key paid-tier benefits.

**Exam tips:**
- The **`cloud` block** replaces a `backend` block; you cannot use both. It enables remote operations + remote state on HCP Terraform.
- **Sentinel = HashiCorp's policy-as-code framework**; OPA is the open-source alternative both supported.
- HCP Terraform **workspaces ≠ CLI workspaces**. HCP workspaces are full environments; CLI workspaces are just multiple states in one backend.
- Remote runs let you keep credentials in HCP (e.g. dynamic provider credentials) rather than on laptops.
- Free tier exists; governance features (Sentinel, SSO, audit) are higher tiers.

---

## Lab 16 — Meta-arguments, CLI workspaces, provisioners (tested throughout)

**Folder:** `lab16-meta/main.tf`
```hcl
terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# count: create N copies, addressed by index
resource "local_file" "by_count" {
  count    = 3
  filename = "${path.module}/count-${count.index}.txt"
  content  = "instance ${count.index}"
}

# for_each: create one per map/set key, addressed by key (stable, preferred for non-identical items)
resource "local_file" "by_foreach" {
  for_each = {
    web = "web server"
    db  = "database"
  }
  filename = "${path.module}/${each.key}.txt"
  content  = each.value
}

# provisioner: last-resort, runs scripts; exam wants you to know they're discouraged
resource "null_resource" "provisioned" {
  provisioner "local-exec" {
    command = "echo provisioner ran"
  }
}
```
Add `null` provider to `required_providers` for the last block.
```bash
terraform init && terraform apply -auto-approve
```

**CLI workspaces (multiple states, one config):**
```bash
terraform workspace list
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform workspace show
# reference inside config with: terraform.workspace
```

**Exam tips:**
- **`count`** uses a number → resources addressed `name[0]`, `name[1]`; uses `count.index`. Removing a middle element re-indexes everything (causes churn).
- **`for_each`** uses a map or set of strings → addressed `name["key"]`; uses `each.key`/`each.value`. Adding/removing one key does **not** disturb others — preferred when items aren't identical.
- You **cannot use both** `count` and `for_each` on the same block.
- **Provisioners are a last resort** (HashiCorp's own guidance). Types: `local-exec` (runs on the machine running Terraform), `remote-exec` (runs on the created resource). `creation`-time by default; `when = destroy` for destroy-time. `on_failure = continue|fail`.
- **CLI workspaces** share one backend and one configuration but keep separate state files; the default workspace is named `default`. Switch with `terraform workspace select`.

---

## CLI Quick Reference (print this)

| Command | Purpose |
|---|---|
| `terraform init` | Initialize dir: providers, modules, backend |
| `terraform init -upgrade` | Update providers within constraints; refresh lock file |
| `terraform init -migrate-state` | Move state to a new backend |
| `terraform init -reconfigure` | Reconfigure backend, ignore existing state |
| `terraform fmt` / `fmt -check` | Format HCL / check formatting (CI) |
| `terraform validate` | Syntax & consistency check (offline) |
| `terraform plan` | Preview changes |
| `terraform plan -out=f` | Save plan to file |
| `terraform apply [f]` | Apply (a saved plan if given) |
| `terraform apply -auto-approve` | Apply without prompt |
| `terraform apply -refresh-only` | Reconcile state with real infra (no infra change) |
| `terraform destroy` | Destroy managed infra |
| `terraform output [-json]` | Show outputs |
| `terraform show` | Human-readable state/plan |
| `terraform state list/show/mv/rm` | Inspect & manipulate state |
| `terraform state pull/push` | Download/upload remote state |
| `terraform import` | Bring existing resource into state |
| `terraform graph` | Output dependency graph |
| `terraform providers` | Show provider requirements |
| `terraform get` | Download/update modules |
| `terraform console` | Interactive expression evaluator |
| `terraform workspace new/select/list` | Manage CLI workspaces |
| `terraform login/logout` | HCP Terraform auth |
| `terraform force-unlock <ID>` | Release a stuck state lock |
| `terraform version` | Versions of CLI + providers |
| `terraform taint`/`untaint` | (Deprecated) mark for recreation → use `-replace` |
| `terraform apply -replace=ADDR` | Force replacement of a resource |

## Top exam traps (last-minute review)

1. **Variable precedence:** CLI `-var` > `*.auto.tfvars` > `terraform.tfvars` > `TF_VAR_*` env. Only `terraform.tfvars`/`*.auto.tfvars` auto-load.
2. **`sensitive = true` ≠ encryption.** State always holds secrets in plaintext.
3. **`validate` is offline** and doesn't detect drift; **`plan` detects drift**.
4. **`init` is required** after adding providers/modules or changing the backend.
5. **Module variables are scoped to the module**; pass data in via inputs, out via outputs only.
6. **`version` constraint** works for providers and registry/git modules — **not** local-path modules.
7. **Lock file (`.terraform.lock.hcl`) should be committed**; it pins exact provider versions.
8. **`count` vs `for_each`:** `for_each` is stable across changes; can't use both on one block.
9. **`depends_on`** only when there's no attribute reference to create an implicit dependency.
10. **`create_before_destroy`** reverses default destroy-then-create order for zero downtime.
11. **`import`/`state rm`/`refresh-only`** change state only, not real infrastructure.
12. **HCP workspaces ≠ CLI workspaces.** Sentinel/OPA = policy as code.
13. **`cloud` block and `backend` block are mutually exclusive.**
14. **Providers are plugins** downloaded at `init`; Terraform core is a single binary.
15. **Custom conditions (004):** `validation` (variables), `precondition`/`postcondition` (lifecycle), `check` (top-level, warns only).

Good luck on the 19th. Work the labs in order, then do timed sample questions from HashiCorp's official 004 sample set.
