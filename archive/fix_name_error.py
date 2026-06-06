import json

target_path = r"C:\Users\Shashwat\OneDrive\Desktop\Mulberry_Yield_Project\notebook4bd5bed4ee.ipynb"

# Load the notebook
with open(target_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Find the cell that contains 'is_healthy_class' and replace it with 'c in HEALTHY_CLASSES'
for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        if 'is_healthy_class' in source:
            # Safely replace the function call with the list membership check
            new_source = source.replace('is_healthy_class(c)', 'c in HEALTHY_CLASSES')
            
            # Repackage the string back into the list format Jupyter uses
            lines = new_source.splitlines(keepends=True)
            cell['source'] = lines
            
            # Clear output just in case
            if 'outputs' in cell:
                cell['outputs'] = []

# Save the updated file
with open(target_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("Fixed the NameError in the Bar Chart plotting cell!")
