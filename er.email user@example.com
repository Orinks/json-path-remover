[1mdiff --git a/README.md b/README.md[m
[1mindex 1260f45..cbbd1ce 100644[m
[1m--- a/README.md[m
[1m+++ b/README.md[m
[36m@@ -1,10 +1,11 @@[m
 # JSON Path Remover[m
 [m
[31m-A Python utility for removing specific paths from JSON files using fuzzy path matching.[m
[32m+[m[32mA Python utility for removing specific paths from JSON files using fuzzy path matching and endpoint targeting.[m
 [m
 ## Features[m
 [m
 - Remove nested paths from JSON files[m
[32m+[m[32m- Find and remove entries pointing to specific files/endpoints[m
 - Fuzzy path matching for easy path selection[m
 - Support for both objects and arrays in JSON structure[m
 - Interactive selection when multiple matches are found[m
[36m@@ -26,7 +27,7 @@[m [mpython json_path_remover.py[m
 [m
 Follow the prompts:[m
 1. Enter the path to your JSON file[m
[31m-2. Enter a partial path to search for[m
[32m+[m[32m2. Enter a file/endpoint to find (e.g., sound.xml)[m
 3. Select the matching path if multiple are found[m
 4. Confirm the removal[m
 [m
[36m@@ -34,12 +35,15 @@[m [mFollow the prompts:[m
 [m
 ```bash[m
 Enter the path to your JSON file: data.json[m
[31m-Enter the partial path to remove: settings/user[m
[32m+[m[32mEnter the file/endpoint to find (e.g. sound.xml): sound.xml[m
 [m
[31m-Found path: settings/user/preferences[m
[31m-Remove this path? (y/n): y[m
[32m+[m[32mMultiple matching paths found:[m
[32m+[m[32m1. resources/audio/background -> /assets/sound.xml[m
[32m+[m[32m2. resources/audio/effects/explosion -> /other/path/sound.xml[m
 [m
[31m-Successfully removed path: settings/user/preferences[m
[32m+[m[32mEnter the number of the path to remove: 1[m
[32m+[m
[32m+[m[32mSuccessfully removed path: resources/audio/background -> /assets/sound.xml[m
 ```[m
 [m
 ## Requirements[m
[1mdiff --git a/json_path_remover.py b/json_path_remover.py[m
[1mindex 5262aab..387c503 100644[m
[1m--- a/json_path_remover.py[m
[1m+++ b/json_path_remover.py[m
[36m@@ -1,5 +1,5 @@[m
 import json[m
[31m-from typing import Any, Dict, List, Union[m
[32m+[m[32mfrom typing import Any, Dict, List, Union, Tuple, Optional[m
 from pathlib import Path[m
 from difflib import get_close_matches[m
 [m
[36m@@ -18,35 +18,56 @@[m [mdef save_json_file(file_path: str, data: Dict[str, Any]) -> None:[m
     with open(file_path, 'w') as f:[m
         json.dump(data, f, indent=2)[m
 [m
[31m-def find_matching_paths(data: Any, partial_path: str, current_path: str = "") -> List[str]:[m
[31m-    """Find all paths in the JSON that match the partial path string."""[m
[31m-    matching_paths = [][m
[32m+[m[32mdef find_matching_paths(data: Any, target_endpoint: str, current_path: str = "") -> List[Tuple[str, str]]:[m
[32m+[m[32m    """Find all paths in the JSON that point to the specified target endpoint.[m
[32m+[m[41m    [m
[32m+[m[32m    Args:[m
[32m+[m[32m        data: The JSON data to search through[m
[32m+[m[32m        target_endpoint: The endpoint/file to match (e.g. 'sound.xml')[m
[32m+[m[32m        current_path: The current path being traversed (used for recursion)[m
[32m+[m[41m    [m
[32m+[m[32m    Returns:[m
[32m+[m[32m        List of tuples containing (path, value) pairs that point to the target endpoint[m
[32m+[m[32m    """[m
[32m+[m[32m    matching_paths: List[Tuple[str, str]] = [][m
     [m
     if isinstance(data, dict):[m
         for key, value in data.items():[m
             new_path = f"{current_path}/{key}" if current_path else key[m
[31m-            if partial_path.lower() in new_path.lower():[m
[31m-                matching_paths.append(new_path)[m
[31m-            matching_paths.extend(find_matching_paths(value, partial_path, new_path))[m
[32m+[m[41m            [m
[32m+[m[32m            # Check if this value points to our target[m
[32m+[m[32m            if isinstance(value, str) and value.lower().endswith(target_endpoint.lower()):[m
[32m+[m[32m                matching_paths.append((new_path, value))[m
[32m+[m[41m            [m
[32m+[m[32m            # Continue searching deeper[m
[32m+[m[32m            matching_paths.extend(find_matching_paths(value, target_endpoint, new_path))[m
[32m+[m[41m            [m
     elif isinstance(data, list):[m
         for i, item in enumerate(data):[m
             new_path = f"{current_path}/{i}"[m
[31m-            matching_paths.extend(find_matching_paths(item, partial_path, new_path))[m
[32m+[m[32m            matching_paths.extend(find_matching_paths(item, target_endpoint, new_path))[m
             [m
     return matching_paths[m
 [m
[31m-def remove_path(data: Any, path_parts: List[str]) -> Union[Dict, List, None]:[m
[31m-    """Remove the specified path from the JSON data."""[m
[32m+[m[32mdef remove_path(data: Any, path_parts: List[str], target_value: Optional[str] = None) -> Union[Dict, List, None]:[m
[32m+[m[32m    """Remove the specified path from the JSON data.[m
[32m+[m[41m    [m
[32m+[m[32m    Args:[m
[32m+[m[32m        data: The JSON data to modify[m
[32m+[m[32m        path_parts: List of path components to traverse[m
[32m+[m[32m        target_value: If provided, only remove if the value matches this[m
[32m+[m[32m    """[m
     if not path_parts:[m
         return None[m
     [m
     if isinstance(data, dict):[m
         key = path_parts[0][m
         if len(path_parts) == 1:[m
[31m-            data.pop(key, None)[m
[32m+[m[32m            if target_value is None or (key in data and data[key] == target_value):[m
[32m+[m[32m                data.pop(key, None)[m
             return data[m
         elif key in data:[m
[31m-            result = remove_path(data[key], path_parts[1:])[m
[32m+[m[32m            result = remove_path(data[key], path_parts[1:], target_value)[m
             if result is not None:[m
                 data[key] = result[m
             return data[m
[36m@@ -55,10 +76,11 @@[m [mdef remove_path(data: Any, path_parts: List[str]) -> Union[Dict, List, None]:[m
             index = int(path_parts[0])[m
             if len(path_parts) == 1:[m
                 if 0 <= index < len(data):[m
[31m-                    data.pop(index)[m
[32m+[m[32m                    if target_value is None or data[index] == target_value:[m
[32m+[m[32m                        data.pop(index)[m
                 return data[m
             elif 0 <= index < len(data):[m
[31m-                result = remove_path(data[index], path_parts[1:])[m
[32m+[m[32m                result = remove_path(data[index], path_parts[1:], target_value)[m
                 if result is not None:[m
                     data[index] = result[m
                 return data[m
[36m@@ -70,44 +92,44 @@[m [mdef remove_path(data: Any, path_parts: List[str]) -> Union[Dict, List, None]:[m
 def main():[m
     # Get input from user[m
     json_file = input("Enter the path to your JSON file: ").strip()[m
[31m-    partial_path = input("Enter the partial path to remove: ").strip()[m
[32m+[m[32m    target_endpoint = input("Enter the file/endpoint to find (e.g. sound.xml): ").strip()[m
     [m
     try:[m
         # Load the JSON file[m
         data = load_json_file(json_file)[m
         [m
         # Find matching paths[m
[31m-        matching_paths = find_matching_paths(data, partial_path)[m
[32m+[m[32m        matching_paths = find_matching_paths(data, target_endpoint)[m
         [m
         if not matching_paths:[m
[31m-            print(f"No paths found matching: {partial_path}")[m
[32m+[m[32m            print(f"No paths found matching: {target_endpoint}")[m
             return[m
         [m
         # If multiple matches found, let user choose[m
         if len(matching_paths) > 1:[m
             print("\nMultiple matching paths found:")[m
[31m-            for i, path in enumerate(matching_paths, 1):[m
[31m-                print(f"{i}. {path}")[m
[32m+[m[32m            for i, (path, value) in enumerate(matching_paths, 1):[m
[32m+[m[32m                print(f"{i}. {path} -> {value}")[m
             [m
             choice = int(input("\nEnter the number of the path to remove: ").strip())[m
             if not (1 <= choice <= len(matching_paths)):[m
                 print("Invalid choice")[m
                 return[m
             [m
[31m-            selected_path = matching_paths[choice - 1][m
[32m+[m[32m            selected_path, selected_value = matching_paths[choice - 1][m
         else:[m
[31m-            selected_path = matching_paths[0][m
[31m-            print(f"\nFound path: {selected_path}")[m
[32m+[m[32m            selected_path, selected_value = matching_paths[0][m
[32m+[m[32m            print(f"\nFound path: {selected_path} -> {selected_value}")[m
             if input("Remove this path? (y/n): ").lower() != 'y':[m
                 return[m
         [m
         # Remove the selected path[m
         path_parts = selected_path.split('/')[m
[31m-        updated_data = remove_path(data, path_parts)[m
[32m+[m[32m        updated_data = remove_path(data, path_parts, selected_value)[m
         [m
         # Save the updated JSON[m
         save_json_file(json_file, updated_data)[m
[31m-        print(f"\nSuccessfully removed path: {selected_path}")[m
[32m+[m[32m        print(f"\nSuccessfully removed path: {selected_path} -> {selected_value}")[m
         [m
     except Exception as e:[m
         print(f"Error: {str(e)}")[m
