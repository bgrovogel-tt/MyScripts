import os
import subprocess
import time
import threading
from xml.etree import ElementTree as ET

# Parses a .csproj file to find project dependencies
def get_project_dependencies(csproj_file):
    try:
        tree = ET.parse(csproj_file)
        root = tree.getroot()
        namespace = {'msbuild': 'http://schemas.microsoft.com/developer/msbuild/2003'}
        dependencies = []

        for project_ref in root.findall(".//msbuild:ProjectReference", namespaces=namespace):
            ref_path = project_ref.get('Include')
            if ref_path:
                normalized_path = os.path.normpath(os.path.join(os.path.dirname(csproj_file), ref_path))
                dependencies.append(normalized_path)
        
        return dependencies
    except Exception as e:
        print(f"Error parsing {csproj_file}: {e}")
        return []

# Gets all .csproj files from a .sln file
def get_csproj_files_from_sln(sln_file):
    csproj_files = []
    sln_dir = os.path.dirname(sln_file)

    try:
        with open(sln_file, 'r') as f:
            for line in f:
                if line.strip().startswith('Project'):
                    parts = line.split('"')
                    if len(parts) >= 6 and parts[5].endswith('.csproj'):
                        csproj_path = os.path.normpath(os.path.join(sln_dir, parts[5]))
                        csproj_files.append(csproj_path)
        return csproj_files
    except FileNotFoundError:
        print(f"Solution file not found: {sln_file}")
        return []
    except Exception as e:
        print(f"Error reading {sln_file}: {e}")
        return []

# Performs topological sorting to determine build order
def topological_sort(dependency_graph):
    visited = set()
    stack = []

    def visit(node):
        if node not in visited:
            visited.add(node)
            for neighbor in dependency_graph.get(node, []):
                visit(neighbor)
            stack.append(node)

    for node in dependency_graph:
        visit(node)

    return stack[::-1]  # Return reversed stack for build order

# Builds the .sln file using MSBuild
def build_solution(sln_file, msbuild_path):
    try:
        print(f"Building {sln_file} using MSBuild...")
        subprocess.run([msbuild_path, sln_file, '/t:build', '/p:Configuration=Release'], check=True)
        print(f"Build succeeded: {sln_file}")
        return True
    except subprocess.CalledProcessError:
        print(f"Build failed: {sln_file}")
        return False

# Finds all .sln files recursively from a given directory
def find_sln_files(directory):
    sln_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.sln'):
                sln_files.append(os.path.join(root, file))
    return sln_files

# Asks the user if they want to continue after a failure
def prompt_continue_after_failure():
    response = None

    def prompt_user():
        nonlocal response
        response = input("A build failed. Do you want to keep going? (y/n): ")

    thread = threading.Thread(target=prompt_user)
    thread.start()
    thread.join(timeout=30)

    return response.lower() == 'y' if response else True

# Determines build order and builds solutions
def build_solutions_in_directory(directory, msbuild_path):
    solution_files = find_sln_files(directory)
    
    if not solution_files:
        print(f"No solution files found in directory: {directory}")
        return

    dependency_graph = {}
    sln_to_csproj = {}

    for sln_file in solution_files:
        csproj_files = get_csproj_files_from_sln(sln_file)
        sln_to_csproj[sln_file] = csproj_files

        for csproj in csproj_files:
            if csproj not in dependency_graph:
                dependency_graph[csproj] = []
            dependencies = get_project_dependencies(csproj)
            dependency_graph[csproj].extend(dependencies)

    build_order = topological_sort(dependency_graph)

    remaining_solutions = list(sln_to_csproj.keys())
    retry_solutions = []
    
    start_time = time.time()
    time_limit = 10 * 60  # 10 minutes

    while remaining_solutions:
        retry_solutions.clear()

        for sln in remaining_solutions:
            elapsed_time = time.time() - start_time
            if elapsed_time > time_limit:
                print("Time limit of 10 minutes reached. Stopping...")
                return

            success = build_solution(sln, msbuild_path)
            if not success:
                if not prompt_continue_after_failure():
                    print("User chose to stop the process.")
                    return
                retry_solutions.append(sln)

        if not retry_solutions:
            print("All solutions built successfully!")
            break

        print(f"{len(retry_solutions)} solutions failed. Retrying after a short delay...")
        time.sleep(5)

        remaining_solutions = retry_solutions[:]

if __name__ == "__main__":
    search_directory = os.getcwd()
    msbuild_path = r"C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    build_solutions_in_directory(search_directory, msbuild_path)