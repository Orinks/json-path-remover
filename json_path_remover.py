import json
from typing import Any, Dict, List, Union
from pathlib import Path
from difflib import get_close_matches

def load_json_file(file_path: str) -> Dict[str, Any]:
    """Load and parse a JSON file."""
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"JSON file not found: {file_path}")
    except json.JSONDecodeError:
        raise ValueError(f"Invalid JSON format in file: {file_path}")

def save_json_file(file_path: str, data: Dict[str, Any]) -> None:
    """Save data to a JSON file with proper formatting."""
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=2)

def find_matching_paths(data: Any, partial_path: str, current_path: str = "") -> List[str]:
    """Find all paths in the JSON that match the partial path string."""
    matching_paths = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            new_path = f"{current_path}/{key}" if current_path else key
            if partial_path.lower() in new_path.lower():
                matching_paths.append(new_path)
            matching_paths.extend(find_matching_paths(value, partial_path, new_path))
    elif isinstance(data, list):
        for i, item in enumerate(data):
            new_path = f"{current_path}/{i}"
            matching_paths.extend(find_matching_paths(item, partial_path, new_path))
            
    return matching_paths

def remove_path(data: Any, path_parts: List[str]) -> Union[Dict, List, None]:
    """Remove the specified path from the JSON data."""
    if not path_parts:
        return None
    
    if isinstance(data, dict):
        key = path_parts[0]
        if len(path_parts) == 1:
            data.pop(key, None)
            return data
        elif key in data:
            result = remove_path(data[key], path_parts[1:])
            if result is not None:
                data[key] = result
            return data
    elif isinstance(data, list):
        try:
            index = int(path_parts[0])
            if len(path_parts) == 1:
                if 0 <= index < len(data):
                    data.pop(index)
                return data
            elif 0 <= index < len(data):
                result = remove_path(data[index], path_parts[1:])
                if result is not None:
                    data[index] = result
                return data
        except ValueError:
            return data
    
    return data

def main():
    # Get input from user
    json_file = input("Enter the path to your JSON file: ").strip()
    partial_path = input("Enter the partial path to remove: ").strip()
    
    try:
        # Load the JSON file
        data = load_json_file(json_file)
        
        # Find matching paths
        matching_paths = find_matching_paths(data, partial_path)
        
        if not matching_paths:
            print(f"No paths found matching: {partial_path}")
            return
        
        # If multiple matches found, let user choose
        if len(matching_paths) > 1:
            print("\nMultiple matching paths found:")
            for i, path in enumerate(matching_paths, 1):
                print(f"{i}. {path}")
            
            choice = int(input("\nEnter the number of the path to remove: ").strip())
            if not (1 <= choice <= len(matching_paths)):
                print("Invalid choice")
                return
            
            selected_path = matching_paths[choice - 1]
        else:
            selected_path = matching_paths[0]
            print(f"\nFound path: {selected_path}")
            if input("Remove this path? (y/n): ").lower() != 'y':
                return
        
        # Remove the selected path
        path_parts = selected_path.split('/')
        updated_data = remove_path(data, path_parts)
        
        # Save the updated JSON
        save_json_file(json_file, updated_data)
        print(f"\nSuccessfully removed path: {selected_path}")
        
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main() 