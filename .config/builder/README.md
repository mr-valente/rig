# Universal Docker build configuration

This directory holds the declarative configuration for the shared Fish build
command:

- `builds.yaml` describes reusable version resolvers, reusable build recipes,
  and the projects that combine them.
- `versions.txt` records the managed SemVer state, one record per project
  component. It is the only file a successful release rewrites.
- The command itself lives in tacklebox, at
  `~/.config/fish/tacklebox/build.fish`. It resolves versions, runs Docker or
  Docker Compose, creates image tags, pushes them, and updates managed SemVer
  state.

Project repositories do not need individual `build.sh` files. The shared
builder intentionally supports image-release workflows; specialized artifact
builders such as Daybreak and USBoss remain outside this configuration.

## Setup

`build.fish` lives in tacklebox, so `~/.config/fish/config.fish` already
sources it along with every other tacklebox file. No separate `source` line is
needed.

The command resolves two locations independently:

- The **configuration file**, `$XDG_CONFIG_HOME/builder/builds.yaml`.
- The **source root**, `$HOME/forge`, which is where project directories are
  resolved. Project paths are relative to this root, *not* to wherever
  `builds.yaml` happens to live.

Either can be overridden for a single invocation. Use `--forge-dir DIRECTORY`
(or `-F DIRECTORY`) to resolve project directories beneath another tree, and
`--config FILE` (or `-c FILE`) to read a different configuration file:

```fish
build --forge-dir /mnt/projects/src --list
build -F /mnt/projects/src --rebuild steamboat
build --config /path/to/builds.yaml --list
build -c /path/to/builds.yaml -F /mnt/projects/src --rebuild steamboat
```

The same two locations can be set through the environment:

```fish
env BUILDER_CONFIG=/path/to/builds.yaml build --list
env BUILDER_FORGE_DIR=/mnt/projects/src build --list
```

The configuration file lookup order is:

1. `--config FILE`.
2. `BUILDER_CONFIG`, when it is set and nonempty.
3. `$XDG_CONFIG_HOME/builder/builds.yaml`, falling back to
   `$HOME/.config/builder/builds.yaml` when `XDG_CONFIG_HOME` is unset.

The source root lookup order is:

1. `--forge-dir DIRECTORY`.
2. `BUILDER_FORGE_DIR`, when it is set and nonempty.
3. `$HOME/forge`.

Flags take precedence over the environment. An override applies only to that
invocation; it does not modify shell state.

Managed SemVer state is not a third configurable location. `versions.txt` is a
sidecar: it is always read from and written to the directory holding the
configuration file, so `--config` and `BUILDER_CONFIG` carry their own version
state with them.

Runtime requirements are Fish, `awk`, Docker, Docker Compose for Compose
recipes, and `curl` when a GitHub release must be resolved. `sudo` is required
when `settings.sudo` is `true`.

## Command overview

```text
build [OPTIONS] PROJECT [COMPONENT OVERRIDES]
```

Common commands:

```fish
build --list
build --forge-dir /mnt/projects/src --list
build --dry-run actual-clerk
build actual-clerk
build --minor paperless-clerk
build --version v1.0.0 grimmory-clerk
build --rebuild actual-clerk
build --no-push --rebuild actual-clerk
build --tag-mod testing lemonade-stand
build steamboat --set sunshine=v2026.123.456 --set usboss=v0.8.0
build tailgate --tailscale 1.92.5 --sablier 1.10.1
```

Run `build --help` for the complete command reference.

## Supported YAML syntax

`builds.yaml` deliberately uses a small, dependency-free subset of YAML. It is
parsed by the shared Fish script rather than a general YAML library.

The supported syntax is:

- Mappings only; YAML sequences are not supported.
- Exactly two spaces per indentation level.
- Unquoted, single-line scalar values.
- Empty lines and whole-line comments beginning with `#`.
- Mapping keys containing letters, digits, `_`, `.`, and `-`, beginning with a
  letter or digit.
- A colon inside a scalar value is allowed because only the first colon on the
  line separates the key from its value.

The following are not supported:

- Tabs.
- Quoted strings.
- YAML lists, inline collections, block scalars, anchors, aliases, or tags.
- Inline comments after a value.
- Empty-string scalar values. A key with no value introduces a nested mapping.
- Duplicate mapping paths.
- Skipping indentation levels or placing child keys beneath a scalar.

Use letters, digits, `_`, and `-` for resolver, recipe, project, and output
names. Do not use `.` in those names because dots separate internal
configuration paths. Component names have the stricter form
`[a-z][a-z0-9_]*`.

Tag collections are written as one space-separated scalar, not as a YAML list:

```yaml
tags: latest {app}
```

## Top-level structure

Schema 3 recognizes exactly these top-level keys:

```yaml
schema: 3

settings:
  sudo: true

resolvers:
  # Named resolver definitions

recipes:
  # Named recipe definitions

projects:
  # Named project definitions
```

Unknown fields are rejected. At least one resolver, recipe, and project must be
defined. The entire configuration and all project directories are validated
before any build operation, including `build --list`.

## `schema`

| Field | Required | Value |
| --- | --- | --- |
| `schema` | Yes | Must be `3` |

The command fails closed when the schema is absent or unsupported. Schema 2
kept each component's version in `builds.yaml` under `current_version`; migrate
by moving every one of those values into `versions.txt` and setting
`schema: 3`.

## `settings`

| Field | Required | Values | Meaning |
| --- | --- | --- | --- |
| `sudo` | Yes | `true`, `false` | Prefix mutating Docker commands with `sudo` |

When enabled, Compose environment assignments are executed in the form
`sudo env NAME=value docker compose ...` so Compose interpolation sees them.
The read-only `docker compose config --images` preflight does not use `sudo`.

## `resolvers`

A resolver defines how a component version is selected and normalized. The
resolver name is referenced by project components.

### SemVer resolver

```yaml
resolvers:
  semver:
    type: semver
```

| Field | Required | Value |
| --- | --- | --- |
| `type` | Yes | `semver` |
| `prefix` | No | Must not be set for this resolver type |

SemVer state is not stored in `builds.yaml`. Each SemVer component has one
record in the `versions.txt` sidecar, described under
[SemVer state and release selection](#semver-state-and-release-selection).
Accepted versions have exactly three numeric parts, optionally beginning with
lowercase `v`, with no leading zeroes except the number zero itself. Prerelease
and build metadata are not supported.

Examples of accepted values are `0.4.2` and `v1.0.0`. Values such as `v01.2.3`,
`1.2`, and `v1.2.3-rc1` are rejected.

### GitHub latest-release resolver

```yaml
resolvers:
  github-tag:
    type: github-latest-release
    prefix: ensure-v
```

| Field | Required | Values | Meaning |
| --- | --- | --- | --- |
| `type` | Yes | `github-latest-release` | Follow the repository's latest-release redirect |
| `prefix` | Yes | `keep`, `strip-v`, `ensure-v` | Normalize the resolved or overridden value |

The resolver requests:

```text
https://github.com/OWNER/REPOSITORY/releases/latest
```

It follows the redirect with `curl`, extracts the final URL segment, rejects an
empty result or `latest`, and then applies `prefix`:

- `keep` leaves the value unchanged.
- `strip-v` removes one leading lowercase `v` when present.
- `ensure-v` adds a lowercase `v` when absent.

This selects GitHub's latest stable release. Drafts and prereleases that GitHub
does not expose through `/releases/latest` are not selected.

Explicit component overrides and configured override environment variables
bypass the network lookup but still receive the resolver's prefix transform.

## `recipes`

A recipe selects the build mechanism and whether the completed images should
normally be pushed.

```yaml
recipes:
  docker-release:
    builder: docker
    push: true

  compose-release:
    builder: compose
    push: true
```

| Field | Required | Values | Meaning |
| --- | --- | --- | --- |
| `builder` | Yes | `docker`, `compose` | Select direct Docker or Docker Compose |
| `push` | Yes | `true`, `false` | Push all expanded output tags after building and tagging |

### `docker` builder

The builder enters the project directory and runs the equivalent of:

```text
docker build [--build-arg NAME=value ...] --tag IMAGE:SOURCE_TAG .
```

A direct Docker project must define exactly one output because that output's
`source_tag` is assigned by `docker build`.

### `compose` builder

The builder enters the project directory and runs the equivalent of:

```text
env NAME=value ... docker compose build --build-arg NAME=value ...
```

Every component build argument is also exported as an environment variable so
the Compose file can use `${NAME}` interpolation. Before building, the command
runs `docker compose config --images` with the same environment and verifies
that every configured `IMAGE:SOURCE_TAG` is actually produced by Compose.

One Compose recipe can therefore describe multiple images, such as Tailgate's
standard and Sablier variants.

When `push` is `true`, pushes are sequential so any failed push stops the
workflow and prevents managed version state from advancing. `--no-push`
overrides the recipe, skips every push, and also suppresses version-state
updates.

## `projects`

Each key under `projects` becomes a name accepted by the `build` command.

```yaml
projects:
  example:
    description: Example image
    directory: example
    recipe: docker-release
    image: owner/example
    primary_component: app
    components:
      # Component definitions
    outputs:
      # Output definitions
```

### Project fields

| Field | Required | Meaning |
| --- | --- | --- |
| `description` | No | Human-readable text displayed by `build --list` |
| `directory` | Yes | Project path relative to the source root (`$HOME/forge`) |
| `recipe` | Yes | Name of a configured recipe |
| `image` | Yes | Repository name shared by all project outputs |
| `primary_component` | When components exist | Component representing the image's release version |
| `tag_modifier` | No | `true` to permit `--tag-mod`; defaults to `false` |
| `tag_modifier_env` | When `tag_modifier` is `true` | Environment variable receiving the raw modifier |
| `components` | No | Named version inputs and Docker build arguments |
| `outputs` | Yes | One or more source images and published tags |

`directory` must be relative, must not contain `..`, and must exist. Each path
segment may contain letters, digits, `_`, `.`, and `-`.

`image` is an untagged lowercase Docker repository name containing letters,
digits, `.`, `_`, `/`, or `-`. Registry names requiring a `host:port` form are
not supported by the current validation rule.

If a project has components, `primary_component` must name one of them. A
project can have at most one SemVer component, and that component must be the
primary component. Projects without components must omit `primary_component`.

## `components`

A component supplies a resolved value to tag templates and a transformed value
to a Docker build argument.

```yaml
components:
  sunshine:
    resolver: github-tag
    repository: LizardByte/Sunshine
    build_arg: SUNSHINE_TAG
    build_transform: keep
    override_env: SUNSHINE_TAG
```

### Component fields

| Field | Required | Meaning |
| --- | --- | --- |
| `resolver` | Yes | Name of a configured resolver |
| `build_arg` | Yes | Docker build-argument and Compose environment-variable name |
| `build_transform` | Yes | `keep`, `strip-v`, or `ensure-v` before passing the build argument |
| `repository` | GitHub resolver | GitHub repository in `OWNER/REPOSITORY` form |
| `override_env` | No, GitHub resolver only | Environment variable that can override GitHub resolution |
| `default_bump` | SemVer resolver | `major`, `minor`, or `patch` |

A SemVer component carries no version of its own. Its current version is a
record in `versions.txt`; `current_version` here is rejected.

`build_arg` and `override_env` use uppercase shell-variable syntax:
`[A-Z_][A-Z0-9_]*`.

Resolver normalization and build transformation are distinct. For example:

```yaml
components:
  app:
    resolver: semver
    default_bump: patch
    build_arg: APP_VERSION
    build_transform: strip-v
```

When `versions.txt` records `v0.3.0` for this component, the resolved component
value and image tag can be `v0.3.1`, while the Docker build receives
`APP_VERSION=0.3.1`. Output templates always use the resolved
component value before `build_transform`.

### Component override priority

For GitHub components, values are selected in this order:

1. A command-line override.
2. The value of `override_env`, if configured and nonempty.
3. A live GitHub latest-release lookup.

The universal override form may be repeated:

```fish
build steamboat \
  --set sunshine=v2026.123.456 \
  --set usboss=v0.8.0
```

Component shorthand is also accepted after the project name:

```fish
build steamboat --sunshine v2026.123.456 --usboss v0.8.0
build tailgate --tailscale=1.92.5 --sablier=1.10.1
```

An override name must match a configured component and may appear only once.
Use `--version`, not `--set`, for a SemVer component.

## `outputs`

An output describes an image created by the builder and the tags to publish
from it.

```yaml
outputs:
  default:
    source_tag: latest
    tags: latest {app}
```

| Field | Required | Meaning |
| --- | --- | --- |
| `source_tag` | Yes | Tag produced directly by Docker or Compose |
| `tags` | Yes | Space-separated tag templates to create and push |

For each output, the builder:

1. Expands `source_tag` and verifies it is a valid Docker tag.
2. Expands each entry in `tags`.
3. Runs `docker tag` when a published tag differs from the source tag.
4. Pushes each unique published tag when the recipe enables pushing.

Two outputs cannot assign the same published tag from different source tags.
Expanded tags must start with a letter, digit, or underscore; may contain
letters, digits, `_`, `.`, and `-`; and may be at most 128 characters.

### Template placeholders

Tag templates can reference any component by name:

```yaml
tags: latest {sunshine}
```

If `sunshine` resolves to `v2026.123.456`, this publishes `latest` and
`v2026.123.456`.

Projects with `tag_modifier: true` can also use `{tag_suffix}`. It expands to
an empty string normally or to `-MODIFIER` when `--tag-mod MODIFIER` is used:

```yaml
tag_modifier: true
tag_modifier_env: TAG_MOD
outputs:
  default:
    source_tag: latest{tag_suffix}
    tags: latest{tag_suffix} {lemonade}{tag_suffix}
```

With `--tag-mod testing`, those templates could expand to `latest-testing` and
`9.1.0-testing`. The raw value `testing` is exported through
`tag_modifier_env`; the hyphen belongs to `{tag_suffix}`.

Unknown placeholders and `{tag_suffix}` on a project without tag modifiers are
rejected during configuration validation.

### Multiple outputs

Tailgate's two image lines are represented without custom shell code:

```yaml
outputs:
  standard:
    source_tag: latest
    tags: latest {tailscale}
  sablier:
    source_tag: latest-with-sablier
    tags: latest-with-sablier {tailscale}-with-sablier
```

If `tailscale` resolves to `1.92.5`, the four published tags are:

```text
latest
1.92.5
latest-with-sablier
1.92.5-with-sablier
```

## SemVer state and release selection

### The `versions.txt` sidecar

Managed SemVer state lives in `versions.txt`, always beside the configuration
file, so `--config /path/to/builds.yaml` reads and writes
`/path/to/versions.txt`.

The format is one record per line:

```text
# Managed SemVer state for build.fish, kept beside builds.yaml.
# One record per line: PROJECT.COMPONENT VERSION

actual-clerk.app     v0.3.3
paperless-clerk.app  v0.1.10
tend.app             v0.3.4
```

- A key is the project name, a dot, and the component name.
- The two fields are separated by spaces or tabs, so records can be aligned in
  columns. A record's existing spacing is preserved when its version changes.
- Blank lines and whole-line comments beginning with `#` are ignored.
- Records must not be indented, must hold exactly two fields, and each key may
  appear only once.

The sidecar and the configuration are validated together before any build,
including `build --list`:

- Every SemVer component must have exactly one record holding a valid version.
- Every record must name a configured SemVer component. Stale records are
  rejected rather than ignored, so a removed or renamed project is noticed.
- `current_version` in `builds.yaml` is rejected as a schema 2 leftover.

Projects without a SemVer component need no record, and a configuration with no
SemVer components at all needs no `versions.txt`.

### Release selection

For a SemVer project, a normal build applies the component's `default_bump`:

```fish
build actual-clerk
```

If the recorded version is `v0.1.0` and `default_bump` is `patch`, the target
is `v0.1.1`.

The selection options are mutually exclusive:

| Option | Result |
| --- | --- |
| `--major` | Increment major and reset minor and patch to zero |
| `--minor` | Increment minor and reset patch to zero |
| `--patch` | Increment patch |
| `--version VERSION` | Use an exact three-part SemVer value |
| `--rebuild` | Reuse the recorded version without changing state |

A successful increment or a higher exact version is saved atomically to the
component's record in `versions.txt`. An exact version equal to or lower than
the recorded version does not move state; a lower version also prints a warning
because publishing it can repoint `latest` backward.

State is updated only after the entire configured workflow succeeds. With a
pushing recipe, every tag must push successfully. The update rereads the
expected version before replacing `versions.txt`, so a concurrent change to the
same component is not overwritten. Comments, record order, and column alignment
in the file survive the rewrite.

`--no-push` always suppresses the state update, even if the local build and tag
operations succeed.

## Rebuilding externally resolved projects

External component versions are not recorded in `versions.txt`. Therefore:

```fish
build --rebuild steamboat
```

resolves GitHub's current latest releases again. If upstream latest releases
have not changed, the build arguments and image tags are identical. If an
upstream project published a new latest release, the rebuild follows it.

To guarantee exact external versions, supply overrides:

```fish
build --rebuild steamboat \
  --sunshine v2026.123.456 \
  --usboss v0.8.0
```

For projects without version components, such as OpenRGB Server, `--rebuild`
simply reuses the configured output tags.

## Dry runs and local-only builds

`--dry-run` performs configuration validation and version resolution, then
prints the build, tag, push, and state plan without invoking Docker or changing
state:

```fish
build --dry-run tailgate --tailscale 1.92.5 --sablier 1.10.1
```

A dry run may contact GitHub for unresolved external components. Supply
component overrides or configured override environment variables to make it
network-independent.

`--no-push` performs the Docker build and local tagging but skips registry
pushes and state changes:

```fish
build --no-push --rebuild actual-clerk
```

## Complete examples

### Managed SemVer Docker image

```yaml
projects:
  example-api:
    description: Example API image
    directory: example-api
    recipe: docker-release
    image: owner/example-api
    primary_component: app
    components:
      app:
        resolver: semver
        default_bump: patch
        build_arg: EXAMPLE_API_VERSION
        build_transform: strip-v
    outputs:
      default:
        source_tag: latest
        tags: latest {app}
```

with one record in `versions.txt`:

```text
example-api.app v0.4.2
```

This builds `owner/example-api:latest`, adds the next version tag, pushes both,
and then saves the successful version back to `versions.txt`.

### GitHub-pinned Compose image

```yaml
projects:
  example-upstream:
    description: Image built from an upstream GitHub release
    directory: example-upstream
    recipe: compose-release
    image: owner/example-upstream
    primary_component: upstream
    components:
      upstream:
        resolver: github-tag
        repository: organization/project
        build_arg: UPSTREAM_TAG
        build_transform: keep
        override_env: UPSTREAM_TAG
    outputs:
      default:
        source_tag: latest
        tags: latest {upstream}
```

The Compose file must produce `owner/example-upstream:latest` and must consume
`UPSTREAM_TAG` as an interpolated build argument or environment value.

### Unversioned Compose image

```yaml
projects:
  example-service:
    description: Unversioned service image
    directory: example-service
    recipe: compose-release
    image: owner/example-service
    outputs:
      default:
        source_tag: latest
        tags: latest
```

No `components` or `primary_component` is needed.

## Adding a project

1. Choose or add a resolver for each version-bearing component.
2. Choose `docker-release` or `compose-release`.
3. Add a project with `directory`, `recipe`, and `image`.
4. Add components and choose a primary component when versions are involved.
5. Map every component to a Docker `build_arg` and `build_transform`.
6. For a SemVer component, add its starting version to `versions.txt` as
   `PROJECT.COMPONENT VERSION`.
7. Define every builder-produced image under `outputs` and list its published
   tag templates.
8. For Compose, ensure `docker compose config --images` includes every
   configured source image name under the configured environment.
9. Validate the result before building:

```fish
build --list
build --dry-run PROJECT --set COMPONENT=VERSION
```

Unknown fields, missing references, malformed or missing versions, stale
`versions.txt` records, invalid templates, missing project directories, and
mismatched Compose source images fail before the mutating build begins.

## Current limitations

- Only direct Docker and Docker Compose image builds are modeled.
- Arbitrary shell fragments and custom artifact-build workflows are not
  supported.
- GitHub resolution supports only the latest-release redirect.
- External resolved versions are not stored as durable state.
- Only one SemVer component is allowed per project.
- SemVer prerelease and build metadata are not supported.
- Direct Docker recipes support exactly one source output.
- Registry repository names containing a port are not accepted.
- The configuration is a strict YAML subset, not general YAML.

These limits keep deterministic versioning, tagging, validation, and state
updates in the shared engine instead of turning the configuration into another
scripting language.
