import json

with open('local_finalclassifier.ipynb', 'r', encoding='utf-8') as f:
    notebook = json.load(f)

# The new cell to insert
new_cell = {
 "cell_type": "code",
 "execution_count": None,
 "id": "kaggle-download-cell",
 "metadata": {},
 "outputs": [],
 "source": [
  "# To download the dataset directly on Vast.ai, input your Kaggle credentials here.\n",
  "# You can get these by going to Kaggle.com -> Account/Settings -> Create New API Token.\n",
  "import os\n",
  "os.environ['KAGGLE_USERNAME'] = \"YOUR_KAGGLE_USERNAME_HERE\"\n",
  "os.environ['KAGGLE_KEY']      = \"YOUR_KAGGLE_API_KEY_HERE\"\n",
  "\n",
  "!pip install -q kaggle\n",
  "!kaggle datasets download nahiduzzaman13/mulberry-leaf-dataset --unzip -d ./datasets/\n",
  "print(\"\\n✅ Dataset downloaded and extracted successfully!\")"
 ]
}

# Insert after the first markdown cell (which is the title)
notebook['cells'].insert(1, new_cell)

with open('local_finalclassifier.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)
