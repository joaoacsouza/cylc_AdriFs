import os
import yaml

# Get the environment variables
name_to_update = os.getenv("name_to_update")
new_value = os.getenv("new_value")

# Ensure the environment variables are set
if not name_to_update or not new_value:
    raise ValueError("Environment variables 'name_to_update' and 'new_value' must be set")

# Load the YAML file
with open("config.yml", "r") as file:
    config = yaml.safe_load(file)

# Update the value
for item in config:
    if item.get('key') == name_to_update:
        item['value'] = new_value

# Write the changes back to the file
with open("config.yml", "w") as file:
    yaml.safe_dump(config, file)

print(f"Updated '{name_to_update}' to '{new_value}' in config.yml")
