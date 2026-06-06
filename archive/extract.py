import json
import sys

def extract(notebook_path, output_path):
    with open(notebook_path, 'r', encoding='utf-8') as f:
        nb = json.load(f)
    
    with open(output_path, 'w', encoding='utf-8') as out:
        for i, cell in enumerate(nb.get('cells', [])):
            if cell.get('cell_type') == 'code':
                out.write(f"----- Cell {i} (Code) -----\n")
                out.write("".join(cell.get('source', [])))
                out.write("\n\n--- Outputs ---\n")
                for output in cell.get('outputs', []):
                    if output.get('output_type') == 'stream':
                        out.write("".join(output.get('text', [])))
                    elif output.get('output_type') == 'execute_result' or output.get('output_type') == 'display_data':
                        data = output.get('data', {})
                        if 'text/plain' in data:
                            out.write("".join(data['text/plain']))
                    elif output.get('output_type') == 'error':
                        out.write(output.get('ename', '') + ": " + output.get('evalue', '') + "\n")
                out.write("\n===========================\n\n")
            elif cell.get('cell_type') == 'markdown':
                out.write(f"----- Cell {i} (Markdown) -----\n")
                out.write("".join(cell.get('source', [])))
                out.write("\n===========================\n\n")

if __name__ == '__main__':
    extract(sys.argv[1], sys.argv[2])
