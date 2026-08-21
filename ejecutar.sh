#!/usr/bin/env bash
# ================================================================================
# EJECUTOR - YouTube to MP3 Converter (Docker)
# ================================================================================
# Single-entry script that runs the CLI inside Docker.
# Requires: Docker Desktop (or docker engine) installed and running.
# Mac / Linux equivalent of ejecutar.ps1
# ================================================================================

set -u

# --- Colored output helpers ---------------------------------------------------
if [ -t 1 ]; then
    C_GREEN=$'\033[32m'
    C_RED=$'\033[31m'
    C_YELLOW=$'\033[33m'
    C_CYAN=$'\033[36m'
    C_GRAY=$'\033[90m'
    C_RESET=$'\033[0m'
else
    C_GREEN=""; C_RED=""; C_YELLOW=""; C_CYAN=""; C_GRAY=""; C_RESET=""
fi

write_color_output() {
    # $1 = message, $2 = color name
    local message="$1"
    local color="${2:-White}"
    case "$color" in
        Green)  printf '%s%s%s\n' "$C_GREEN" "$message" "$C_RESET" ;;
        Red)    printf '%s%s%s\n' "$C_RED" "$message" "$C_RESET" ;;
        Yellow) printf '%s%s%s\n' "$C_YELLOW" "$message" "$C_RESET" ;;
        Cyan)   printf '%s%s%s\n' "$C_CYAN" "$message" "$C_RESET" ;;
        Gray)   printf '%s%s%s\n' "$C_GRAY" "$message" "$C_RESET" ;;
        *)      printf '%s\n' "$message" ;;
    esac
}

write_error_custom() { write_color_output "[ERROR] $1" "Red"; }
write_info()         { write_color_output "[INFO] $1" "Cyan"; }
write_warn()         { write_color_output "[WARNING] $1" "Yellow"; }

# --- Path helpers -------------------------------------------------------------
# Prints the absolute path of an existing file/directory, fails if it does not exist.
resolve_existing_path() {
    local target="$1"
    if [ -d "$target" ]; then
        (cd -- "$target" 2>/dev/null && pwd -P)
        return
    fi
    if [ -e "$target" ]; then
        local dir base
        dir=$(dirname -- "$target")
        base=$(basename -- "$target")
        dir=$(cd -- "$dir" 2>/dev/null && pwd -P) || return 1
        printf '%s/%s\n' "${dir%/}" "$base"
        return
    fi
    return 1
}

# Joins a (possibly relative) path with the script directory.
join_script_root() {
    local target="$1"
    case "$target" in
        /*) printf '%s\n' "$target" ;;
        *)  printf '%s/%s\n' "${SCRIPT_ROOT%/}" "$target" ;;
    esac
}

SCRIPT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# --- Ensure we are in the project directory -----------------------------------
if [ ! -f "$SCRIPT_ROOT/descargar_audio.py" ]; then
    write_error_custom "This script must be run from the project directory."
    write_info "Expected to find descargar_audio.py next to this script."
    exit 1
fi

# --- Check Docker availability ------------------------------------------------
if ! docker --version >/dev/null 2>&1; then
    write_error_custom "Docker is not installed or not available in PATH."
    write_info "Install Docker Desktop and try again."
    exit 1
fi

# --- Directories --------------------------------------------------------------
downloads_dir="$SCRIPT_ROOT/downloads"
logs_dir="$SCRIPT_ROOT/logs"

if [ ! -d "$downloads_dir" ]; then
    mkdir -p "$downloads_dir"
    write_info "Created downloads directory: $downloads_dir"
fi

if [ ! -d "$logs_dir" ]; then
    mkdir -p "$logs_dir"
    write_info "Created logs directory: $logs_dir"
fi

# --- Docker image ---------------------------------------------------------------
image_name="y2m-cli"
image_exists=$(docker images -q "$image_name" 2>/dev/null)

if [ -z "$image_exists" ]; then
    write_info "Building Docker image..."
    if ! docker build -t "$image_name" "$SCRIPT_ROOT"; then
        write_error_custom "Docker image build failed."
        exit 1
    fi
    write_info "Docker image built successfully."
fi

# --- Argument processing --------------------------------------------------------
script_args=()
input_mount=""
output_mount=""
found_output_arg=false
csv_provided=false
allow_no_csv=false

while [ "$#" -gt 0 ]; do
    arg="$1"

    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ] || [ "$arg" = "--version" ]; then
        allow_no_csv=true
        script_args+=("$arg")
        shift
        continue
    fi

    if [ "$arg" = "-o" ] || [ "$arg" = "--output-dir" ]; then
        if [ "$#" -lt 2 ]; then
            write_error_custom "Missing value for -o/--output-dir."
            exit 1
        fi

        out_raw="$2"
        if ! out_path=$(resolve_existing_path "$out_raw"); then
            out_path=$(join_script_root "$out_raw")
        fi

        # Ensure output directory exists
        if [ ! -d "$out_path" ]; then
            mkdir -p "$out_path"
        fi

        if ! output_mount=$(resolve_existing_path "$out_path"); then
            write_error_custom "Could not resolve output directory: $out_raw"
            exit 1
        fi
        found_output_arg=true

        script_args+=("$arg" "/app/output")
        shift 2
        continue
    fi

    case "$arg" in
        -*)
            script_args+=("$arg")
            shift
            continue
            ;;
    esac

    if [ "$csv_provided" = true ]; then
        write_error_custom "Only one CSV file is allowed."
        exit 1
    fi

    csv_raw="$arg"
    if ! csv_path=$(resolve_existing_path "$csv_raw"); then
        if ! csv_path=$(resolve_existing_path "$(join_script_root "$csv_raw")"); then
            write_error_custom "CSV file not found: $csv_raw"
            exit 1
        fi
    fi

    csv_dir=$(dirname -- "$csv_path")
    csv_file=$(basename -- "$csv_path")

    if [ -n "$input_mount" ] && [ "$input_mount" != "$csv_dir" ]; then
        write_error_custom "Only one CSV directory can be mounted per run."
        write_info "Place all CSV files in the same folder and try again."
        exit 1
    fi

    input_mount="$csv_dir"
    script_args+=("/app/input/$csv_file")
    csv_provided=true
    shift
done

if [ "$csv_provided" = false ] && [ "$allow_no_csv" = false ]; then
    write_error_custom "Missing CSV file. Usage: ./ejecutar.sh <urls.csv> [-o <output-dir>]"
    exit 1
fi

# If no output dir provided, force container output to /app/downloads
if [ "$found_output_arg" = false ]; then
    script_args+=("-o" "/app/downloads")
fi

# --- Docker run arguments -------------------------------------------------------
run_args=("--rm" "-i")

# Only allocate a TTY when running interactively (docker fails otherwise)
if [ -t 0 ] && [ -t 1 ]; then
    run_args+=("-t")
fi

run_args+=(
    "-v" "${downloads_dir}:/app/downloads"
    "-v" "${logs_dir}:/app/logs"
)

if [ -n "$input_mount" ]; then
    run_args+=("-v" "${input_mount}:/app/input:ro")
fi

if [ -n "$output_mount" ] && [ "$output_mount" != "$downloads_dir" ]; then
    run_args+=("-v" "${output_mount}:/app/output")
fi

run_args+=("$image_name")
run_args+=("${script_args[@]}")

write_info "Running CLI in Docker..."
write_color_output "[INFO] Args: ${script_args[*]}" "Gray"

docker run "${run_args[@]}"
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    write_color_output "[OK] Completed successfully." "Green"
    write_info "Downloads: $downloads_dir"
    write_info "Logs: $logs_dir"
else
    write_warn "Process finished with exit code: $exit_code"
fi

exit "$exit_code"
