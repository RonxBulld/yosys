#include <iostream>
#include <string>
#include <vector>
#include <cstring>
#include <unistd.h>
#include <getopt.h>
#include <readline/readline.h>
#include <readline/history.h>

// Function to display usage information
void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [options] [command]\n"
              << "Options:\n"
              << "  -i              Enter interactive mode\n"
              << "  -h, --help      Display this help message\n"
              << "  -v, --version   Display version information\n"
              << std::endl;
}

// Function to execute a command
int execute_command(const std::string& command) {
    // TODO: Implement actual command execution logic
    std::cout << "Executing: " << command << std::endl;
    return 0;
}

// Custom completion function
char** command_completion(const char* text, int /*start*/, int /*end*/) {
    // Disable default filename completion
    rl_attempted_completion_over = 1;
    
    // Use readline's completion matches function
    return rl_completion_matches(text, [](const char* text, int state) -> char* {
        static int index;
        static size_t len;
        const char* name;
        
        static const char* commands[] = {
            "help", "exit", "quit", "clear", "history",
            "run", "exec", "show", "list", "status",
            nullptr
        };
        
        if (!state) {
            index = 0;
            len = strlen(text);
        }
        
        while ((name = commands[index++])) {
            if (strncmp(name, text, len) == 0) {
                return strdup(name);
            }
        }
        
        return nullptr;
    });
}

// Function to handle interactive mode
void interactive_mode() {
    std::cout << "Entering interactive mode. Type 'exit' or 'quit' to leave.\n";
    std::cout << "Type 'help' for available commands.\n\n";
    
    // Initialize readline
    using_history();
    
    // Set up custom tab completion
    rl_attempted_completion_function = command_completion;
    
    // Load history from file if it exists
    const char* history_file = ".launcher_history";
    read_history(history_file);
    
    while (true) {
        // Read input with readline
        char* input = readline("launcher> ");
        
        if (input == nullptr) {
            // EOF (Ctrl+D)
            std::cout << "\n";
            break;
        }
        
        std::string command(input);
        
        // Skip empty commands
        if (command.empty()) {
            free(input);
            continue;
        }
        
        // Add to history
        add_history(input);
        
        // Check for exit commands
        if (command == "exit" || command == "quit") {
            free(input);
            break;
        }
        
        // Check for help command
        if (command == "help") {
            std::cout << "Available commands:\n"
                      << "  help    - Show this help message\n"
                      << "  exit    - Exit interactive mode\n"
                      << "  quit    - Exit interactive mode\n"
                      << "  clear   - Clear the screen\n"
                      << "  history - Show command history\n"
                      << std::endl;
        }
        else if (command == "clear") {
            if (system("clear") != 0) {
                std::cerr << "Failed to clear screen\n";
            }
        }
        else if (command == "history") {
            // Display history
            HIST_ENTRY** hist_list = history_list();
            if (hist_list) {
                for (int i = 0; hist_list[i]; i++) {
                    std::cout << " " << i + 1 << "  " << hist_list[i]->line << std::endl;
                }
            }
        }
        else {
            // Execute the command
            execute_command(command);
        }
        
        free(input);
    }
    
    // Save history to file
    write_history(history_file);
    
    std::cout << "Exiting interactive mode.\n";
}

int main(int argc, char* argv[]) {
    bool interactive = false;
    
    // Parse command line options
    static struct option long_options[] = {
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}
    };
    
    int opt;
    int option_index = 0;
    
    while ((opt = getopt_long(argc, argv, "ihv", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'i':
                interactive = true;
                break;
            case 'h':
                print_usage(argv[0]);
                return 0;
            case 'v':
                std::cout << "launcher version 1.0.0\n";
                return 0;
            case '?':
                // Invalid option
                print_usage(argv[0]);
                return 1;
            default:
                break;
        }
    }
    
    if (interactive) {
        // Enter interactive mode
        interactive_mode();
    } else {
        // Execute command from command line arguments
        if (optind < argc) {
            std::string command;
            for (int i = optind; i < argc; i++) {
                if (i > optind) command += " ";
                command += argv[i];
            }
            return execute_command(command);
        } else {
            std::cout << "No command specified. Use -i for interactive mode.\n";
            print_usage(argv[0]);
            return 1;
        }
    }
    
    return 0;
}