# Launcher Tool

A command-line launcher with interactive mode support using GNU readline and history libraries.

## Features

- Interactive mode with command-line editing and history
- Command history persistence across sessions
- Tab completion support with custom command completion
- Non-interactive command execution mode
- Command-line editing with arrow keys, Ctrl+A/E, etc.

## Building

### Prerequisites

You need to have the following libraries installed:
- GNU readline development library
- GNU history library (usually comes with readline)

On Ubuntu/Debian:
```bash
sudo apt-get install libreadline-dev
```

On Fedora/RHEL:
```bash
sudo dnf install readline-devel
```

On macOS (with Homebrew):
```bash
brew install readline
```

### Compilation

```bash
cd tools
make
```

## Usage

### Interactive Mode

Start the launcher in interactive mode with the `-i` option:

```bash
./launcher -i
```

In interactive mode:
- Type commands at the `launcher>` prompt
- Use arrow keys to navigate command history
- Tab completion is available for built-in commands (help, exit, quit, clear, history, run, exec, show, list, status)
- Commands are saved to `.launcher_history` file
- Standard readline shortcuts work (Ctrl+A for beginning of line, Ctrl+E for end, etc.)

Available interactive commands:
- `help` - Display available commands
- `history` - Show command history
- `clear` - Clear the screen
- `exit` or `quit` - Exit interactive mode
- Ctrl+D - Exit interactive mode

### Non-Interactive Mode

Execute a single command:

```bash
./launcher [command] [arguments]
```

### Options

- `-i` - Enter interactive mode
- `-h, --help` - Display help message
- `-v, --version` - Display version information

## Examples

```bash
# Start interactive mode
./launcher -i

# Execute a command directly
./launcher mycommand arg1 arg2

# Get help
./launcher -h
```

## Implementation Notes

The launcher uses:
- GNU readline for command-line editing
- GNU history for command history management
- History is saved to `.launcher_history` in the current directory
- The `execute_command()` function is a placeholder that should be implemented with actual command execution logic