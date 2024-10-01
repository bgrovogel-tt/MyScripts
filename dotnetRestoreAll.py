import subprocess
import sys
import os

# ANSI escape codes for coloring
RED = '\033[91m'  # Red text
RESET = '\033[0m'  # Reset to default color

def run_dotnet_restore(solution_file):
    try:
        # Run the dotnet restore command
        result = subprocess.run(
            ['dotnet', 'restore', solution_file],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Print the output from the command
        print(f"Restoring {solution_file}...\nOutput:\n{result.stdout}")

    except subprocess.CalledProcessError as e:
        # Print error in red and continue
        print(f"{RED}Error occurred while running dotnet restore on {solution_file}:{RESET}")
        print("Return code:", e.returncode)
        print("Output:\n", e.output)
        print("Error message:\n", e.stderr)

def find_sln_files(directory):
    sln_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.sln'):
                sln_files.append(os.path.join(root, file))
    return sln_files

if __name__ == "__main__":
    print("Starting script execution...")

    # Specify the directory to search for .sln files
    search_directory = '.'  # Current directory or specify another path
    print(f"Searching for .sln files in: {search_directory}")
    
    sln_files = find_sln_files(search_directory)

    if not sln_files:
        print("No .sln files found in the specified directory.")
    else:
        print(f"Found .sln files: {sln_files}")
        for sln_file in sln_files:
            print(f"Running dotnet restore on: {sln_file}")
            run_dotnet_restore(sln_file)

    print("Script execution finished.")
