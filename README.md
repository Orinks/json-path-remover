# JSON Path Remover

A Python utility for removing specific paths from JSON files using fuzzy path matching and endpoint targeting.

## Features

- Remove nested paths from JSON files
- Find and remove entries pointing to specific files/endpoints
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
2. Enter a file/endpoint to find (e.g., sound.xml)
3. Select the matching path if multiple are found
4. Confirm the removal

## Example

```bash
Enter the path to your JSON file: data.json
Enter the file/endpoint to find (e.g. sound.xml): sound.xml

Multiple matching paths found:
1. resources/audio/background -> /assets/sound.xml
2. resources/audio/effects/explosion -> /other/path/sound.xml

Enter the number of the path to remove: 1

Successfully removed path: resources/audio/background -> /assets/sound.xml
```

## Requirements

- Python 3.6+ 