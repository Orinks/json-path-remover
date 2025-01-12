import json
from typing import Any, Dict, List, Union, Tuple, Optional
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

def find_matching_paths(data: Any, target_endpoint: str, current_path: str = "") -> List[Tuple[str, str]]:
    """Find all paths in the JSON that point to the specified target endpoint.
    
    Args:
        data: The JSON data to search through
        target_endpoint: The endpoint/file to match (e.g. 'sound.xml')
        current_path: The current path being traversed (used for recursion)
    
    Returns:
        List of tuples containing (path, value) pairs that point to the target endpoint
    """
    matching_paths: List[Tuple[str, str]] = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            new_path = f"{current_path}/{key}" if current_path else key
            
            # Check if this value points to our target
            if isinstance(value, str) and value.lower().endswith(target_endpoint.lower()):
                matching_paths.append((new_path, value))
            
            # Continue searching deeper
            matching_paths.extend(find_matching_paths(value, target_endpoint, new_path))
            
    elif isinstance(data, list):
        for i, item in enumerate(data):
            new_path = f"{current_path}/{i}"
            matching_paths.extend(find_matching_paths(item, target_endpoint, new_path))
            
    return matching_paths

def remove_path(data: Any, path_parts: List[str], target_value: Optional[str] = None) -> Union[Dict, List, None]:
    """Remove the specified path from the JSON data.
    
    Args:
        data: The JSON data to modify
        path_parts: List of path components to traverse
        target_value: If provided, only remove if the value matches this
    """
    if not path_parts:
        return None
    
    if isinstance(data, dict):
        key = path_parts[0]
        if len(path_parts) == 1:
            if target_value is None or (key in data and data[key] == target_value):
                data.pop(key, None)
            return data
        elif key in data:
            result = remove_path(data[key], path_parts[1:], target_value)
            if result is not None:
                data[key] = result
            return data
    elif isinstance(data, list):
        try:
            index = int(path_parts[0])
            if len(path_parts) == 1:
                if 0 <= index < len(data):
                    if target_value is None or data[index] == target_value:
                        data.pop(index)
                return data
            elif 0 <= index < len(data):
                result = remove_path(data[index], path_parts[1:], target_value)
                if result is not None:
                    data[index] = result
                return data
        except ValueError:
            return data
    
    return data

def main():
    # Get input from user
    json_file = input("Enter the path to your JSON file: ").strip()
    target_endpoint = input("Enter the file/endpoint to find (e.g. sound.xml): ").strip()
    
    try:
        # Load the JSON file
        data = load_json_file(json_file)
        
        # Find matching paths
        matching_paths = find_matching_paths(data, target_endpoint)
        
        if not matching_paths:
            print(f"No paths found matching: {target_endpoint}")
            return
        
        # If multiple matches found, let user choose
        if len(matching_paths) > 1:
            print("\nMultiple matching paths found:")
            for i, (path, value) in enumerate(matching_paths, 1):
                print(f"{i}. {path} -> {value}")
            
            choice = int(input("\nEnter the number of the path to remove: ").strip())
            if not (1 <= choice <= len(matching_paths)):
                print("Invalid choice")
                return
            
            selected_path, selected_value = matching_paths[choice - 1]
        else:
            selected_path, selected_value = matching_paths[0]
            print(f"\nFound path: {selected_path} -> {selected_value}")
            if input("Remove this path? (y/n): ").lower() != 'y':
                return
        
        # Remove the selected path
        path_parts = selected_path.split('/')
        updated_data = remove_path(data, path_parts, selected_value)
        
        # Save the updated JSON
        save_json_file(json_file, updated_data)
        print(f"\nSuccessfully removed path: {selected_path} -> {selected_value}")
        
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main() 