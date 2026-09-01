# Sourced automatically from config.fish along with the rest of tacklebox.
#
# Reads its configuration from $XDG_CONFIG_HOME/builder/builds.yaml and builds
# the projects checked out under $HOME/forge.  Both locations can be overridden
# -- see $BUILDER_CONFIG / --config and $BUILDER_FORGE_DIR / --forge-dir below.

function __forge_build_error
    printf 'build: %s\n' "$argv" >&2
end

function __forge_build_config_file --argument-names config_override
    if test -n "$config_override"
        builtin path resolve "$config_override" 2>/dev/null
    else if set -q BUILDER_CONFIG; and test -n "$BUILDER_CONFIG"
        builtin path resolve "$BUILDER_CONFIG" 2>/dev/null
    else if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        builtin path resolve "$XDG_CONFIG_HOME/builder/builds.yaml" 2>/dev/null
    else
        builtin path resolve "$HOME/.config/builder/builds.yaml" 2>/dev/null
    end
end

# The source root is resolved independently of the configuration file: project
# directories are relative to the checkout tree, not to wherever builds.yaml
# happens to live.
function __forge_build_forge_dir --argument-names forge_override
    if test -n "$forge_override"
        builtin path resolve "$forge_override" 2>/dev/null
    else if set -q BUILDER_FORGE_DIR; and test -n "$BUILDER_FORGE_DIR"
        builtin path resolve "$BUILDER_FORGE_DIR" 2>/dev/null
    else
        builtin path resolve "$HOME/forge" 2>/dev/null
    end
end

function __forge_build_yaml_lint --argument-names config_file
    command awk '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        function make_path(last_level, result, position) {
            result = keys[0]
            for (position = 1; position <= last_level; position++) {
                result = result "." keys[position]
            }
            return result
        }

        /^[[:space:]]*($|#)/ { next }

        {
            raw = $0
            if (index(raw, "\t") != 0) {
                print "tabs are not supported at line " NR > "/dev/stderr"
                failed = 1
                next
            }

            indent = 0
            while (substr(raw, indent + 1, 1) == " ") {
                indent++
            }

            if (indent % 2 != 0) {
                print "indentation must use multiples of two spaces at line " NR > "/dev/stderr"
                failed = 1
                next
            }

            level = indent / 2
            if (seen_line && level > previous_level + 1) {
                print "indentation jumps more than one level at line " NR > "/dev/stderr"
                failed = 1
            }

            if (scalar_level >= 0 && level > scalar_level) {
                print "a scalar value cannot have children at line " NR > "/dev/stderr"
                failed = 1
            }
            if (scalar_level >= 0 && level <= scalar_level) {
                scalar_level = -1
            }

            content = substr(raw, indent + 1)
            separator = index(content, ":")
            if (separator < 2) {
                print "expected a mapping key at line " NR > "/dev/stderr"
                failed = 1
                next
            }

            key = substr(content, 1, separator - 1)
            value = trim(substr(content, separator + 1))
            if (key !~ /^[A-Za-z0-9][A-Za-z0-9_.-]*$/) {
                print "invalid mapping key at line " NR ": " key > "/dev/stderr"
                failed = 1
            }
            first_character = substr(value, 1, 1)
            if (first_character == "\"" || first_character == sprintf("%c", 39)) {
                print "quoted scalars are not supported at line " NR > "/dev/stderr"
                failed = 1
            }

            keys[level] = key
            path = make_path(level)
            if (paths[path]++) {
                print "duplicate configuration path at line " NR ": " path > "/dev/stderr"
                failed = 1
            }

            if (value != "") {
                scalar_level = level
            }
            previous_level = level
            seen_line = 1
        }

        END { exit failed ? 1 : 0 }
    ' "$config_file"
end

function __forge_build_yaml_query --argument-names config_file mode wanted_path
    command awk -v mode="$mode" -v wanted="$wanted_path" '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        function make_path(last_level, result, position) {
            if (last_level < 0) {
                return ""
            }
            result = keys[0]
            for (position = 1; position <= last_level; position++) {
                result = result "." keys[position]
            }
            return result
        }

        /^[[:space:]]*($|#)/ { next }

        {
            raw = $0
            indent = 0
            while (substr(raw, indent + 1, 1) == " ") {
                indent++
            }
            level = indent / 2
            content = substr(raw, indent + 1)
            separator = index(content, ":")
            key = substr(content, 1, separator - 1)
            value = trim(substr(content, separator + 1))
            keys[level] = key
            path = make_path(level)
            parent = make_path(level - 1)

            if (mode == "children" && parent == wanted) {
                print key
            } else if (mode == "value" && path == wanted && value != "") {
                print value
            }
        }
    ' "$config_file"
end

function __forge_build_config_get --argument-names config_file path
    __forge_build_yaml_query "$config_file" value "$path"
end

function __forge_build_config_children --argument-names config_file path
    __forge_build_yaml_query "$config_file" children "$path"
end

function __forge_build_validate_template --argument-names project template tag_modifier
    set -l components $argv[4..-1]
    set -l placeholders (string match -ra '\{[a-z][a-z0-9_]*\}' -- "$template")

    for placeholder in $placeholders
        set -l name (string replace -a '{' '' -- (string replace -a '}' '' -- "$placeholder"))
        if test "$name" = tag_suffix
            if test "$tag_modifier" != true
                __forge_build_error "project '$project' uses {tag_suffix} but tag_modifier is not enabled"
                return 1
            end
        else if not contains -- "$name" $components
            __forge_build_error "project '$project' uses unknown template component '{$name}'"
            return 1
        end
    end

    set -l without_placeholders (string replace -ra '\{[a-z][a-z0-9_]*\}' X -- "$template")
    if not string match -qr '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -- "$without_placeholders"
        __forge_build_error "project '$project' has an invalid tag template: $template"
        return 1
    end
end

function __forge_build_validate_config --argument-names config_file forge_dir
    if test -z "$forge_dir"; or not test -d "$forge_dir"
        __forge_build_error "source directory not found: $forge_dir"
        return 1
    end
    if test -z "$config_file"; or not test -f "$config_file"
        __forge_build_error "configuration file not found: $config_file"
        return 1
    end
    if not test -r "$config_file"
        __forge_build_error "configuration file is not readable: $config_file"
        return 1
    end

    __forge_build_yaml_lint "$config_file"
    or begin
        __forge_build_error "invalid YAML structure in $config_file"
        return 1
    end

    if test (__forge_build_config_get "$config_file" schema) != 2
        __forge_build_error "unsupported or missing schema in $config_file (expected schema: 2)"
        return 1
    end

    set -l top_level (__forge_build_config_children "$config_file" '')
    for field in $top_level
        if not contains -- "$field" schema settings resolvers recipes projects
            __forge_build_error "unknown top-level field '$field'"
            return 1
        end
    end

    set -l use_sudo (__forge_build_config_get "$config_file" settings.sudo)
    if not contains -- "$use_sudo" true false
        __forge_build_error 'settings.sudo must be true or false'
        return 1
    end
    for field in (__forge_build_config_children "$config_file" settings)
        if not contains -- "$field" sudo
            __forge_build_error "unknown settings field '$field'"
            return 1
        end
    end

    set -l resolvers (__forge_build_config_children "$config_file" resolvers)
    if test (count $resolvers) -eq 0
        __forge_build_error 'at least one resolver must be configured'
        return 1
    end
    for resolver in $resolvers
        set -l path "resolvers.$resolver"
        set -l resolver_type (__forge_build_config_get "$config_file" "$path.type")
        for field in (__forge_build_config_children "$config_file" "$path")
            if not contains -- "$field" type prefix
                __forge_build_error "unknown field '$field' for resolver '$resolver'"
                return 1
            end
        end
        if not contains -- "$resolver_type" semver github-latest-release
            __forge_build_error "resolver '$resolver' has invalid type '$resolver_type'"
            return 1
        end
        set -l prefix (__forge_build_config_get "$config_file" "$path.prefix")
        if test "$resolver_type" = github-latest-release
            if not contains -- "$prefix" keep strip-v ensure-v
                __forge_build_error "resolver '$resolver' needs prefix keep, strip-v, or ensure-v"
                return 1
            end
        else if test -n "$prefix"
            __forge_build_error "semver resolver '$resolver' must not define prefix"
            return 1
        end
    end

    set -l recipes (__forge_build_config_children "$config_file" recipes)
    if test (count $recipes) -eq 0
        __forge_build_error 'at least one recipe must be configured'
        return 1
    end
    for recipe in $recipes
        set -l path "recipes.$recipe"
        for field in (__forge_build_config_children "$config_file" "$path")
            if not contains -- "$field" builder push
                __forge_build_error "unknown field '$field' for recipe '$recipe'"
                return 1
            end
        end
        set -l builder (__forge_build_config_get "$config_file" "$path.builder")
        set -l push (__forge_build_config_get "$config_file" "$path.push")
        if not contains -- "$builder" docker compose
            __forge_build_error "recipe '$recipe' has invalid builder '$builder'"
            return 1
        end
        if not contains -- "$push" true false
            __forge_build_error "recipe '$recipe' must set push to true or false"
            return 1
        end
    end

    set -l projects (__forge_build_config_children "$config_file" projects)
    if test (count $projects) -eq 0
        __forge_build_error 'at least one project must be configured'
        return 1
    end
    for project in $projects
        set -l path "projects.$project"
        for field in (__forge_build_config_children "$config_file" "$path")
            if not contains -- "$field" description directory recipe image primary_component tag_modifier tag_modifier_env components outputs
                __forge_build_error "unknown field '$field' for project '$project'"
                return 1
            end
        end

        set -l directory (__forge_build_config_get "$config_file" "$path.directory")
        set -l recipe (__forge_build_config_get "$config_file" "$path.recipe")
        set -l image (__forge_build_config_get "$config_file" "$path.image")
        if test -z "$directory" -o -z "$recipe" -o -z "$image"
            __forge_build_error "project '$project' must define directory, recipe, and image"
            return 1
        end
        if not string match -qr '^[A-Za-z0-9][A-Za-z0-9_.-]*(/[A-Za-z0-9][A-Za-z0-9_.-]*)*$' -- "$directory"
            __forge_build_error "project '$project' has invalid relative directory '$directory'"
            return 1
        end
        if not test -d (builtin path normalize "$forge_dir/$directory")
            __forge_build_error "project '$project' directory does not exist: $forge_dir/$directory"
            return 1
        end
        if not contains -- "$recipe" $recipes
            __forge_build_error "project '$project' references unknown recipe '$recipe'"
            return 1
        end
        if not string match -qr '^[a-z0-9][a-z0-9._/-]*$' -- "$image"
            __forge_build_error "project '$project' has invalid image name '$image'"
            return 1
        end

        set -l tag_modifier (__forge_build_config_get "$config_file" "$path.tag_modifier")
        if test -z "$tag_modifier"
            set tag_modifier false
        end
        if not contains -- "$tag_modifier" true false
            __forge_build_error "project '$project' tag_modifier must be true or false"
            return 1
        end
        set -l tag_modifier_env (__forge_build_config_get "$config_file" "$path.tag_modifier_env")
        if test "$tag_modifier" = true
            if not string match -qr '^[A-Z_][A-Z0-9_]*$' -- "$tag_modifier_env"
                __forge_build_error "project '$project' must define a valid tag_modifier_env"
                return 1
            end
        else if test -n "$tag_modifier_env"
            __forge_build_error "project '$project' defines tag_modifier_env without enabling tag_modifier"
            return 1
        end

        set -l components (__forge_build_config_children "$config_file" "$path.components")
        set -l primary (__forge_build_config_get "$config_file" "$path.primary_component")
        if test (count $components) -gt 0
            if not contains -- "$primary" $components
                __forge_build_error "project '$project' must select a configured primary_component"
                return 1
            end
        else if test -n "$primary"
            __forge_build_error "project '$project' has primary_component but no components"
            return 1
        end

        set -l semver_components
        for component in $components
            if not string match -qr '^[a-z][a-z0-9_]*$' -- "$component"
                __forge_build_error "project '$project' has invalid component name '$component'"
                return 1
            end
            set -l component_path "$path.components.$component"
            for field in (__forge_build_config_children "$config_file" "$component_path")
                if not contains -- "$field" resolver repository current_version default_bump build_arg build_transform override_env
                    __forge_build_error "unknown field '$field' for component '$project.$component'"
                    return 1
                end
            end

            set -l resolver (__forge_build_config_get "$config_file" "$component_path.resolver")
            set -l build_arg (__forge_build_config_get "$config_file" "$component_path.build_arg")
            set -l transform (__forge_build_config_get "$config_file" "$component_path.build_transform")
            if not contains -- "$resolver" $resolvers
                __forge_build_error "component '$project.$component' references unknown resolver '$resolver'"
                return 1
            end
            if not string match -qr '^[A-Z_][A-Z0-9_]*$' -- "$build_arg"
                __forge_build_error "component '$project.$component' needs a valid build_arg"
                return 1
            end
            if not contains -- "$transform" keep strip-v ensure-v
                __forge_build_error "component '$project.$component' needs build_transform keep, strip-v, or ensure-v"
                return 1
            end
            set -l override_env (__forge_build_config_get "$config_file" "$component_path.override_env")
            if test -n "$override_env"; and not string match -qr '^[A-Z_][A-Z0-9_]*$' -- "$override_env"
                __forge_build_error "component '$project.$component' has invalid override_env '$override_env'"
                return 1
            end

            set -l resolver_type (__forge_build_config_get "$config_file" "resolvers.$resolver.type")
            if test "$resolver_type" = semver
                set -a semver_components "$component"
                set -l current (__forge_build_config_get "$config_file" "$component_path.current_version")
                set -l default_bump (__forge_build_config_get "$config_file" "$component_path.default_bump")
                if not string match -qr '^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -- "$current"
                    __forge_build_error "component '$project.$component' has invalid current_version '$current'"
                    return 1
                end
                if not contains -- "$default_bump" major minor patch
                    __forge_build_error "component '$project.$component' needs default_bump major, minor, or patch"
                    return 1
                end
            else
                set -l repository (__forge_build_config_get "$config_file" "$component_path.repository")
                if not string match -qr '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -- "$repository"
                    __forge_build_error "component '$project.$component' has invalid GitHub repository '$repository'"
                    return 1
                end
            end
        end

        if test (count $semver_components) -gt 1
            __forge_build_error "project '$project' has more than one semver component"
            return 1
        end
        if test (count $semver_components) -eq 1; and test "$primary" != "$semver_components[1]"
            __forge_build_error "project '$project' semver component must be primary_component"
            return 1
        end

        set -l outputs (__forge_build_config_children "$config_file" "$path.outputs")
        if test (count $outputs) -eq 0
            __forge_build_error "project '$project' must define at least one output"
            return 1
        end
        set -l builder (__forge_build_config_get "$config_file" "recipes.$recipe.builder")
        if test "$builder" = docker; and test (count $outputs) -ne 1
            __forge_build_error "docker project '$project' must define exactly one output"
            return 1
        end

        for output in $outputs
            set -l output_path "$path.outputs.$output"
            for field in (__forge_build_config_children "$config_file" "$output_path")
                if not contains -- "$field" source_tag tags
                    __forge_build_error "unknown field '$field' for output '$project.$output'"
                    return 1
                end
            end
            set -l source_tag (__forge_build_config_get "$config_file" "$output_path.source_tag")
            set -l tags (__forge_build_config_get "$config_file" "$output_path.tags")
            if test -z "$source_tag" -o -z "$tags"
                __forge_build_error "output '$project.$output' must define source_tag and tags"
                return 1
            end
            __forge_build_validate_template "$project" "$source_tag" "$tag_modifier" $components
            or return 1
            for tag in (string split ' ' -- "$tags")
                if test -n "$tag"
                    __forge_build_validate_template "$project" "$tag" "$tag_modifier" $components
                    or return 1
                end
            end
        end
    end
end

function __forge_build_apply_prefix --argument-names value prefix
    switch "$prefix"
        case keep
            printf '%s\n' "$value"
        case strip-v
            string replace -r '^v' '' -- "$value"
        case ensure-v
            if string match -q 'v*' -- "$value"
                printf '%s\n' "$value"
            else
                printf 'v%s\n' "$value"
            end
    end
end

function __forge_build_resolve_github --argument-names repository component
    if not command -q curl
        __forge_build_error "curl is required to resolve GitHub component '$component'"
        return 1
    end

    set -l release_url "https://github.com/$repository/releases/latest"
    set -l resolved_url (command curl -fsSLI -o /dev/null -w '%{url_effective}' "$release_url")
    or begin
        __forge_build_error "failed to resolve latest '$component' release from $release_url"
        return 1
    end

    set -l tag (string replace -r '^.*/' '' -- "$resolved_url")
    if test -z "$tag"; or test "$tag" = latest
        __forge_build_error "failed to parse latest '$component' release tag from $resolved_url"
        return 1
    end
    printf '%s\n' "$tag"
end

function __forge_build_semver_increment --argument-names input_version bump
    set -l prefix
    if string match -q 'v*' -- "$input_version"
        set prefix v
    end
    set -l parts (string split . -- (string replace -r '^v' '' -- "$input_version"))
    set -l major "$parts[1]"
    set -l minor "$parts[2]"
    set -l patch "$parts[3]"
    switch "$bump"
        case major
            set major (math "$major + 1")
            set minor 0
            set patch 0
        case minor
            set minor (math "$minor + 1")
            set patch 0
        case patch
            set patch (math "$patch + 1")
    end
    printf '%s%s.%s.%s\n' "$prefix" "$major" "$minor" "$patch"
end

function __forge_build_semver_normalize --argument-names input_version reference_version
    set -l prefix
    if string match -q 'v*' -- "$reference_version"
        set prefix v
    end
    printf '%s%s\n' "$prefix" (string replace -r '^v' '' -- "$input_version")
end

function __forge_build_semver_compare --argument-names left right
    set -l left_parts (string split . -- (string replace -r '^v' '' -- "$left"))
    set -l right_parts (string split . -- (string replace -r '^v' '' -- "$right"))
    for index in 1 2 3
        if test "$left_parts[$index]" -gt "$right_parts[$index]"
            printf '1\n'
            return
        else if test "$left_parts[$index]" -lt "$right_parts[$index]"
            printf '%s\n' -1
            return
        end
    end
    printf '0\n'
end

function __forge_build_expand_template --argument-names template tag_suffix
    set -l result (string replace -a -- '{tag_suffix}' "$tag_suffix" "$template")
    for pair in $argv[3..-1]
        set -l parts (string split -m 1 '=' -- "$pair")
        set result (string replace -a -- "{$parts[1]}" "$parts[2]" "$result")
    end
    if string match -qr '\{[^}]+\}' -- "$result"
        __forge_build_error "unresolved tag template: $result"
        return 1
    end
    printf '%s\n' "$result"
end

function __forge_build_print_command
    set -l escaped
    for argument in $argv
        set -a escaped (string escape -- "$argument")
    end
    string join ' ' -- $escaped
end

function __forge_build_save_version --argument-names config_file project component expected_version new_version
    set -l version_path "projects.$project.components.$component.current_version"
    set -l observed_version (__forge_build_config_get "$config_file" "$version_path")
    if test "$observed_version" != "$expected_version"
        __forge_build_error "not updating $config_file: '$project.$component' changed from $expected_version to $observed_version during the build"
        return 1
    end

    set -l config_dir (builtin path dirname "$config_file")
    set -l temp_file (command mktemp "$config_dir/.builds.yaml.XXXXXX")
    if test $status -ne 0 -o -z "$temp_file"
        __forge_build_error "could not create a temporary configuration file in $config_dir"
        return 1
    end

    command awk -v target_project="$project" -v target_component="$component" -v replacement="$new_version" '
        /^  [A-Za-z0-9][A-Za-z0-9_.-]*:[[:space:]]*$/ {
            project = $0
            sub(/^  /, "", project)
            sub(/:[[:space:]]*$/, "", project)
        }
        project == target_project && /^    components:[[:space:]]*$/ {
            in_components = 1
            next_line = 1
        }
        in_components && /^    [A-Za-z0-9]/ && !/^    components:/ {
            in_components = 0
        }
        in_components && /^      [A-Za-z0-9][A-Za-z0-9_]*:[[:space:]]*$/ {
            component = $0
            sub(/^      /, "", component)
            sub(/:[[:space:]]*$/, "", component)
        }
        project == target_project && in_components && component == target_component && /^        current_version:[[:space:]]*/ {
            print "        current_version: " replacement
            changed++
            next
        }
        { print }
        END { if (changed != 1) exit 42 }
    ' "$config_file" >"$temp_file"
    set -l awk_status $status
    if test $awk_status -ne 0
        command rm -f -- "$temp_file"
        __forge_build_error "could not update current_version for '$project.$component'"
        return 1
    end

    command chmod --reference="$config_file" "$temp_file"
    and command mv -- "$temp_file" "$config_file"
    or begin
        command rm -f -- "$temp_file"
        __forge_build_error "could not atomically replace $config_file"
        return 1
    end
end

function __forge_build_usage
    printf '%s\n' \
        'Usage: build [OPTIONS] PROJECT [COMPONENT OVERRIDES]' \
        '' \
        'Resolve versions, build, tag, and push a configured Docker project.' \
        '' \
        'Options:' \
        '  -M, --major                Increment the configured major version' \
        '  -m, --minor                Increment the configured minor version' \
        '  -p, --patch                Increment the configured patch version' \
        '  -v, --version X.Y.Z        Build an exact SemVer version' \
        '  -r, --rebuild              Reuse SemVer state; resolved projects reuse latest when unchanged' \
        '  -s, --set NAME=VERSION     Override a component; may be repeated' \
        '  -t, --tag-mod NAME         Apply the configured image-tag modifier' \
        '  -F, --forge-dir DIRECTORY  Look for project directories under DIRECTORY' \
        '                             instead of $HOME/forge' \
        '  -c, --config FILE          Read FILE instead of' \
        '                             $XDG_CONFIG_HOME/builder/builds.yaml' \
        '      --no-push              Build and tag locally without pushing or saving version state' \
        '  -n, --dry-run              Resolve and print the plan without Docker changes' \
        '  -l, --list                 List configured projects' \
        '  -h, --help                 Show this help' \
        '' \
        'Component shorthand is also accepted, such as --sunshine VERSION.' \
        'SemVer projects use their configured default bump when omitted.' \
        '' \
        'Examples:' \
        '  build actual-clerk' \
        '  build --rebuild actual-clerk' \
        '  build --minor paperless-clerk' \
        '  build --version v1.0.0 grimmory-clerk' \
        '  build --tag-mod testing lemonade-stand' \
        '  build steamboat --set sunshine=v2026.123.456 --set usboss=v0.8.0' \
        '  build tailgate --tailscale 1.92.5 --sablier 1.10.1'
end

function build --description 'Resolve, build, tag, and push a configured Docker project'
    argparse --name=build --ignore-unknown \
        h/help \
        l/list \
        n/dry-run \
        M/major \
        m/minor \
        p/patch \
        r/rebuild \
        'F/forge-dir=' \
        'c/config=' \
        'v/version=' \
        's/set=+' \
        't/tag-mod=' \
        no-push \
        -- $argv
    or return 2

    if set -q _flag_help
        __forge_build_usage
        return 0
    end

    set -l config_file (__forge_build_config_file "$_flag_config")
    set -l forge_dir (__forge_build_forge_dir "$_flag_forge_dir")
    __forge_build_validate_config "$config_file" "$forge_dir"
    or return 1

    set -l projects (__forge_build_config_children "$config_file" projects)
    if set -q _flag_list
        if test (count $argv) -gt 0
            __forge_build_error '--list does not accept a project or overrides'
            return 2
        end
        printf 'Configured builds:\n'
        for configured_project in $projects
            set -l description (__forge_build_config_get "$config_file" "projects.$configured_project.description")
            printf '  %-20s %s\n' "$configured_project" "$description"
        end
        return 0
    end

    if test (count $argv) -eq 0
        __forge_build_error 'a project name is required (use build --list)'
        return 2
    end

    set -l project "$argv[1]"
    if not contains -- "$project" $projects
        __forge_build_error "unknown project '$project' (use build --list)"
        return 2
    end

    set -l path "projects.$project"
    set -l components (__forge_build_config_children "$config_file" "$path.components")
    set -l override_entries $_flag_set
    set -l shorthand $argv[2..-1]
    while test (count $shorthand) -gt 0
        set -l token "$shorthand[1]"
        set -e shorthand[1]
        if string match -qr '^--[a-z][a-z0-9_]*=.+' -- "$token"
            set -a override_entries (string replace -r '^--' '' -- "$token")
        else if string match -qr '^--[a-z][a-z0-9_]*$' -- "$token"
            set -l name (string replace -r '^--' '' -- "$token")
            if test (count $shorthand) -eq 0; or string match -q -- '--*' "$shorthand[1]"
                __forge_build_error "component override '$token' needs a value"
                return 2
            end
            set -a override_entries "$name=$shorthand[1]"
            set -e shorthand[1]
        else
            __forge_build_error "unexpected argument '$token'"
            return 2
        end
    end

    set -l override_names
    set -l override_values
    for entry in $override_entries
        if not string match -qr '^[a-z][a-z0-9_]*=.+' -- "$entry"
            __forge_build_error "invalid component override '$entry' (expected NAME=VERSION)"
            return 2
        end
        set -l parts (string split -m 1 '=' -- "$entry")
        if not contains -- "$parts[1]" $components
            __forge_build_error "project '$project' has no component '$parts[1]'"
            return 2
        end
        if contains -- "$parts[1]" $override_names
            __forge_build_error "component '$parts[1]' was overridden more than once"
            return 2
        end
        set -a override_names "$parts[1]"
        set -a override_values "$parts[2]"
    end

    set -l version_option_count 0
    for flag_name in _flag_major _flag_minor _flag_patch _flag_version
        if set -q $flag_name
            set version_option_count (math "$version_option_count + 1")
        end
    end
    set -l version_selection_count $version_option_count
    if set -q _flag_rebuild
        set version_selection_count (math "$version_selection_count + 1")
    end
    if test $version_selection_count -gt 1
        __forge_build_error '--major, --minor, --patch, --version, and --rebuild are mutually exclusive'
        return 2
    end

    set -l primary (__forge_build_config_get "$config_file" "$path.primary_component")
    set -l semver_component
    for component in $components
        set -l resolver (__forge_build_config_get "$config_file" "$path.components.$component.resolver")
        if test (__forge_build_config_get "$config_file" "resolvers.$resolver.type") = semver
            set semver_component "$component"
        end
    end
    if test $version_option_count -gt 0; and test -z "$semver_component"
        __forge_build_error "project '$project' uses resolved component versions; use --set NAME=VERSION"
        return 2
    end
    if test -n "$semver_component"; and contains -- "$semver_component" $override_names
        __forge_build_error "use --version rather than --set for semver component '$semver_component'"
        return 2
    end

    set -l tag_modifier (__forge_build_config_get "$config_file" "$path.tag_modifier")
    if test -z "$tag_modifier"
        set tag_modifier false
    end
    set -l tag_suffix
    if set -q _flag_tag_mod
        if test "$tag_modifier" != true
            __forge_build_error "project '$project' does not support tag modifiers"
            return 2
        end
        if not string match -qr '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -- "$_flag_tag_mod"; or test (string length -- "$_flag_tag_mod") -gt 64
            __forge_build_error "invalid tag modifier '$_flag_tag_mod'"
            return 2
        end
        set tag_suffix "-$_flag_tag_mod"
    end

    set -l component_names
    set -l component_values
    set -l component_pairs
    set -l current_version
    set -l target_version
    set -l should_save_version 0
    set -l version_warning

    for component in $components
        set -l component_path "$path.components.$component"
        set -l resolver (__forge_build_config_get "$config_file" "$component_path.resolver")
        set -l resolver_type (__forge_build_config_get "$config_file" "resolvers.$resolver.type")
        set -l value

        if test "$resolver_type" = semver
            set current_version (__forge_build_config_get "$config_file" "$component_path.current_version")
            if set -q _flag_rebuild
                set value "$current_version"
            else if set -q _flag_version
                if not string match -qr '^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -- "$_flag_version"
                    __forge_build_error "invalid SemVer '$_flag_version' (expected vMAJOR.MINOR.PATCH)"
                    return 2
                end
                set value (__forge_build_semver_normalize "$_flag_version" "$current_version")
                set -l comparison (__forge_build_semver_compare "$value" "$current_version")
                if test "$comparison" -gt 0
                    set should_save_version 1
                else if test "$comparison" -lt 0
                    set version_warning 'this older version may repoint the image latest tag; version state will not move backward'
                end
            else
                set -l bump (__forge_build_config_get "$config_file" "$component_path.default_bump")
                set -q _flag_major; and set bump major
                set -q _flag_minor; and set bump minor
                set -q _flag_patch; and set bump patch
                set value (__forge_build_semver_increment "$current_version" "$bump")
                set should_save_version 1
            end
            set target_version "$value"
        else
            set -l override_index (contains -i -- "$component" $override_names)
            if test -n "$override_index"
                set value "$override_values[$override_index]"
            else
                set -l override_env (__forge_build_config_get "$config_file" "$component_path.override_env")
                if test -n "$override_env"; and set -q $override_env; and test -n "$$override_env"
                    set value "$$override_env"
                else
                    set -l repository (__forge_build_config_get "$config_file" "$component_path.repository")
                    set value (__forge_build_resolve_github "$repository" "$component")
                    or return 1
                end
            end
            set -l prefix (__forge_build_config_get "$config_file" "resolvers.$resolver.prefix")
            set value (__forge_build_apply_prefix "$value" "$prefix")
        end

        if test -z "$value"; or string match -qr '[[:space:]]' -- "$value"
            __forge_build_error "component '$component' resolved to an invalid empty or whitespace-containing value"
            return 1
        end
        set -a component_names "$component"
        set -a component_values "$value"
        set -a component_pairs "$component=$value"
    end

    set -l build_options
    set -l compose_environment
    for index in (seq (count $component_names))
        set -l component "$component_names[$index]"
        set -l value "$component_values[$index]"
        set -l component_path "$path.components.$component"
        set -l build_arg (__forge_build_config_get "$config_file" "$component_path.build_arg")
        set -l transform (__forge_build_config_get "$config_file" "$component_path.build_transform")
        set -l build_value (__forge_build_apply_prefix "$value" "$transform")
        set -a build_options --build-arg "$build_arg=$build_value"
        set -a compose_environment "$build_arg=$build_value"
    end
    if set -q _flag_tag_mod
        set -l tag_modifier_env (__forge_build_config_get "$config_file" "$path.tag_modifier_env")
        set -a compose_environment "$tag_modifier_env=$_flag_tag_mod"
    end

    set -l image (__forge_build_config_get "$config_file" "$path.image")
    set -l output_names (__forge_build_config_children "$config_file" "$path.outputs")
    set -l source_images
    set -l publish_images
    set -l publish_sources
    for output in $output_names
        set -l output_path "$path.outputs.$output"
        set -l source_template (__forge_build_config_get "$config_file" "$output_path.source_tag")
        set -l source_tag (__forge_build_expand_template "$source_template" "$tag_suffix" $component_pairs)
        or return 1
        if not string match -qr '^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$' -- "$source_tag"
            __forge_build_error "output '$output' produced invalid Docker tag '$source_tag'"
            return 1
        end
        set -l source_image "$image:$source_tag"
        set -a source_images "$source_image"

        set -l tag_templates (__forge_build_config_get "$config_file" "$output_path.tags")
        for template in (string split ' ' -- "$tag_templates")
            if test -z "$template"
                continue
            end
            set -l tag (__forge_build_expand_template "$template" "$tag_suffix" $component_pairs)
            or return 1
            if not string match -qr '^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$' -- "$tag"
                __forge_build_error "output '$output' produced invalid Docker tag '$tag'"
                return 1
            end
            set -l target_image "$image:$tag"
            set -l existing_index (contains -i -- "$target_image" $publish_images)
            if test -n "$existing_index"
                if test "$publish_sources[$existing_index]" != "$source_image"
                    __forge_build_error "tag '$target_image' is produced by more than one source output"
                    return 1
                end
            else
                set -a publish_images "$target_image"
                set -a publish_sources "$source_image"
            end
        end
    end

    set -l recipe (__forge_build_config_get "$config_file" "$path.recipe")
    set -l builder (__forge_build_config_get "$config_file" "recipes.$recipe.builder")
    set -l recipe_push (__forge_build_config_get "$config_file" "recipes.$recipe.push")
    set -l use_sudo (__forge_build_config_get "$config_file" settings.sudo)
    set -l command_prefix
    if test "$use_sudo" = true
        set command_prefix sudo
    end

    set -l build_command $command_prefix
    if test "$builder" = compose; and test (count $compose_environment) -gt 0
        set -a build_command env $compose_environment
    end
    if test "$builder" = docker
        set -a build_command docker build $build_options --tag "$source_images[1]" .
    else
        set -a build_command docker compose build $build_options
    end

    printf 'Project:   %s\n' "$project"
    printf 'Directory: %s\n' (builtin path normalize "$forge_dir/"(__forge_build_config_get "$config_file" "$path.directory"))
    for index in (seq (count $component_names))
        printf 'Component: %-12s %s\n' "$component_names[$index]" "$component_values[$index]"
    end
    if set -q _flag_rebuild
        if test -n "$semver_component"
            printf 'Rebuild:   reused configured version %s\n' "$current_version"
        else if test (count $components) -gt 0
            printf 'Rebuild:   resolved latest components; tags stay unchanged when upstream latest is unchanged\n'
        else
            printf 'Rebuild:   reused configured output tags\n'
        end
    end
    printf 'Build:     %s\n' (__forge_build_print_command $build_command)
    for index in (seq (count $publish_images))
        if test "$publish_images[$index]" != "$publish_sources[$index]"
            printf 'Tag:       %s -> %s\n' "$publish_sources[$index]" "$publish_images[$index]"
        end
    end
    if test "$recipe_push" = true; and not set -q _flag_no_push
        for target_image in $publish_images
            printf 'Push:      %s\n' "$target_image"
        end
    else
        printf 'Push:      skipped\n'
    end
    if test -n "$semver_component"
        if test $should_save_version -eq 1; and not set -q _flag_no_push
            printf 'State:     save %s after successful workflow\n' "$target_version"
        else
            printf 'State:     unchanged\n'
        end
    end
    if test -n "$version_warning"
        printf 'Warning:   %s\n' "$version_warning"
    end

    if set -q _flag_dry_run
        printf 'Dry run:   no Docker or state changes performed\n'
        return 0
    end

    if not command -q docker
        __forge_build_error 'docker is required'
        return 1
    end
    if test "$use_sudo" = true; and not command -q sudo
        __forge_build_error 'sudo is required by settings.sudo'
        return 1
    end

    set -l project_dir (builtin path normalize "$forge_dir/"(__forge_build_config_get "$config_file" "$path.directory"))
    pushd "$project_dir" >/dev/null
    or begin
        __forge_build_error "could not enter project directory: $project_dir"
        return 1
    end

    if test "$builder" = compose
        set -l compose_config_command
        if test (count $compose_environment) -gt 0
            set compose_config_command env $compose_environment
        end
        set -a compose_config_command docker compose config --images
        set -l compose_images (command $compose_config_command)
        set -l config_status $status
        if test $config_status -ne 0
            popd >/dev/null
            __forge_build_error "docker compose config failed with status $config_status"
            return $config_status
        end
        for source_image in $source_images
            if not contains -- "$source_image" $compose_images
                popd >/dev/null
                __forge_build_error "Compose does not produce configured source image '$source_image'"
                return 1
            end
        end
    end

    command $build_command
    set -l build_status $status
    if test $build_status -ne 0
        popd >/dev/null
        __forge_build_error "'$project' build failed with status $build_status; version state was not changed"
        return $build_status
    end

    for index in (seq (count $publish_images))
        if test "$publish_images[$index]" != "$publish_sources[$index]"
            set -l tag_command $command_prefix docker tag "$publish_sources[$index]" "$publish_images[$index]"
            command $tag_command
            set -l tag_status $status
            if test $tag_status -ne 0
                popd >/dev/null
                __forge_build_error "tagging '$publish_images[$index]' failed with status $tag_status"
                return $tag_status
            end
        end
    end

    if test "$recipe_push" = true; and not set -q _flag_no_push
        for target_image in $publish_images
            set -l push_command $command_prefix docker push "$target_image"
            command $push_command
            set -l push_status $status
            if test $push_status -ne 0
                popd >/dev/null
                __forge_build_error "pushing '$target_image' failed with status $push_status; version state was not changed"
                return $push_status
            end
        end
    end
    popd >/dev/null

    if test -n "$semver_component"; and test $should_save_version -eq 1; and not set -q _flag_no_push
        __forge_build_save_version "$config_file" "$project" "$semver_component" "$current_version" "$target_version"
        or return 1
        printf 'Saved %s as the current version for %s.\n' "$target_version" "$project"
    end
end

# Fish completion helpers.  These live beside the command because build.fish is
# sourced directly from the user's Fish configuration rather than installed as
# a command-specific completion file.
function __forge_build_completion_config_file
    set -l tokens (commandline -opc)
    set -l config_override
    set -l index 2

    while test $index -le (count $tokens)
        set -l token "$tokens[$index]"
        switch "$token"
            case --config -c
                set index (math "$index + 1")
                if test $index -le (count $tokens)
                    set config_override "$tokens[$index]"
                end
            case '--config=*'
                set config_override (string split -m 1 '=' -- "$token")[2]
        end
        set index (math "$index + 1")
    end

    __forge_build_config_file "$config_override" 2>/dev/null
end

function __forge_build_completion_projects_condition
    set -l current_token (commandline -ct)
    if string match -q -- '-*' "$current_token"
        return 1
    end

    set -l tokens (commandline -opc)
    set -l expecting_value 0
    set -l positional_count 0
    set -l after_options 0
    set -l index 2

    while test $index -le (count $tokens)
        set -l token "$tokens[$index]"
        if test $expecting_value -eq 1
            set expecting_value 0
        else if test $after_options -eq 1
            set positional_count (math "$positional_count + 1")
        else
            switch "$token"
                case --
                    set after_options 1
                case --forge-dir -F --config -c --version -v --set -s --tag-mod -t
                    set expecting_value 1
                case '-*'
                    # Boolean options do not affect the positional slot.
                case '*'
                    set positional_count (math "$positional_count + 1")
            end
        end
        set index (math "$index + 1")
    end

    test $expecting_value -eq 0; and test $positional_count -eq 0
end

function __forge_build_completion_projects
    set -l config_file (__forge_build_completion_config_file)
    if test -z "$config_file"; or not test -f "$config_file"
        return 0
    end

    for project in (__forge_build_config_children "$config_file" projects 2>/dev/null)
        set -l description (__forge_build_config_get "$config_file" "projects.$project.description" 2>/dev/null)
        set -l directory (__forge_build_config_get "$config_file" "projects.$project.directory" 2>/dev/null)
        if test -n "$directory"; and test -n "$description"
            printf '%s\t%s (%s)\n' "$project" "$description" "$directory"
        else if test -n "$description"
            printf '%s\t%s\n' "$project" "$description"
        else
            printf '%s\n' "$project"
        end
    end
end

complete -c build -s h -l help -f -d 'Show this help'
complete -c build -s l -l list -f -d 'List configured projects'
complete -c build -s n -l dry-run -f -d 'Resolve and print the plan without Docker changes'
complete -c build -s M -l major -f -d 'Increment the configured major version'
complete -c build -s m -l minor -f -d 'Increment the configured minor version'
complete -c build -s p -l patch -f -d 'Increment the configured patch version'
complete -c build -s r -l rebuild -f -d 'Reuse SemVer state'
complete -c build -l no-push -f -d 'Build locally without pushing or saving version state'
complete -c build -s v -l version -r -f -d 'Build an exact SemVer version'
complete -c build -s s -l set -r -d 'Override a component version'
complete -c build -s t -l tag-mod -r -f -d 'Apply the configured image-tag modifier'
complete -c build -s F -l forge-dir -r -a '(__fish_complete_directories)' -d 'Look for project directories under this directory'
complete -c build -s c -l config -r -F -d 'Read this builds.yaml instead of the configured one'
complete -c build -n __forge_build_completion_projects_condition -f -a '(__forge_build_completion_projects)' -d 'Configured project'
