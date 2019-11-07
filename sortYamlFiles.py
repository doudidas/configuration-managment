
import yaml
import sys
import os

# Get folder path from user argument
folder_path = sys.argv[1]
# Get all file names on the folder
file_names  = os.listdir(folder_path)
# Loop on each files
for file_name in file_names:
    # Set path to current file
    file_path = folder_path + "/" + file_name
    # Read file
    with open(file_path, 'r') as f:
        # Load yaml into an object
        data = yaml.load(f, Loader=yaml.FullLoader)
        # Generate yaml string with key sorted
        sorted = yaml.dump(data, sort_keys=True)
    with open(file_path, 'w') as f:
        # Saved sorted yaml string into the file
        f.write(sorted)