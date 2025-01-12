# JSON Path Remover

A Python utility for removing specific paths from JSON files using fuzzy path matching.

## Features

- Remove nested paths from JSON files
- Fuzzy path matching for easy path selection
- Support for both objects and arrays in JSON structure
- Interactive selection when multiple matches are found
- Preserves JSON formatting

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/json-path-remover.git
cd json-path-remover
```

## Usage

Run the script:
```bash
python json_path_remover.py
```

Follow the prompts:
1. Enter the path to your JSON file
2. Enter a partial path to search for
3. Select the matching path if multiple are found
4. Confirm the removal

## Example

```bash
Enter the path to your JSON file: data.json
Enter the partial path to remove: settings/user

Found path: settings/user/preferences
Remove this path? (y/n): y

Successfully removed path: settings/user/preferences
```

## Requirements

- Python 3.6+ 