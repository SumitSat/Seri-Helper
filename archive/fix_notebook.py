import json

with open('finalclassifier.ipynb', 'r', encoding='utf-8') as f:
    notebook = json.load(f)

for cell in notebook['cells']:
    if 'outputs' in cell:
        cell['outputs'] = []
    if 'metadata' in cell:
        # remove execution metadata which might be large/unnecessary
        if 'execution' in cell['metadata']:
            del cell['metadata']['execution']
    
    if 'source' in cell:
        if isinstance(cell['source'], list):
            cell['source'] = [line.replace('/kaggle/input/', './datasets/').replace('/kaggle/working/', './working/') for line in cell['source']]
        elif isinstance(cell['source'], str):
            cell['source'] = cell['source'].replace('/kaggle/input/', './datasets/').replace('/kaggle/working/', './working/')

# Remove kaggle specific metadata if present
if 'metadata' in notebook and 'kaggle' in notebook['metadata']:
    del notebook['metadata']['kaggle']

with open('local_finalclassifier.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)
