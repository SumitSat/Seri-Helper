import json

with open('local_finalclassifier.ipynb', 'r', encoding='utf-8') as f:
    notebook = json.load(f)

for cell in notebook['cells']:
    if cell.get('id') == 'kaggle-download-cell':
        cell['source'] = [
            "# Dataset download cell with provided credentials.\n",
            "import os\n",
            "os.environ['KAGGLE_USERNAME'] = \"sambodhisolutions\"\n",
            "os.environ['KAGGLE_KEY']      = \"KGAT_b6f2372e9d3c30c47fd7185e7de50522\"\n",
            "\n",
            "!pip install -q kaggle\n",
            "!kaggle datasets download nahiduzzaman13/mulberry-leaf-dataset --unzip -d ./datasets/\n",
            "print(\"\\n✅ Dataset downloaded and extracted successfully!\")"
        ]

with open('local_finalclassifier.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)
