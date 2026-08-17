import os
import glob
import argparse

BASE = os.path.dirname(os.path.abspath(__file__))

def get_latest_file(directory):
    files = glob.glob(os.path.join(BASE, directory, "*.md"))
    if not files:
        return None
    return max(files, key=os.path.getmtime)

def combine(project_name=None):
    files_to_combine = [
        os.path.join(BASE, "context", "me.md"),
        os.path.join(BASE, "context", "prompts_for_ai.md")
    ]
    
    # Add active project context
    if project_name:
        status_file = os.path.join(BASE, "projects", project_name, "_status.md")
        if os.path.exists(status_file):
            files_to_combine.append(status_file)
        else:
            print(f"Предупреждение: Файл {status_file} не найден.")
        
        main_project_file = os.path.join(BASE, "projects", project_name, f"{project_name}.md")
        if os.path.exists(main_project_file):
            files_to_combine.append(main_project_file)
            
    # Add latest journal entry
    latest_journal = get_latest_file("journal")
    if latest_journal:
        files_to_combine.append(latest_journal)
        
    out_path = os.path.join(BASE, "combined_docs.md")
    with open(out_path, "w", encoding="utf-8") as out:
        for f in files_to_combine:
            if os.path.exists(f):
                out.write(f"\n\n--- {os.path.relpath(f, BASE)} ---\n\n")
                with open(f, "r", encoding="utf-8") as infile:
                    out.write(infile.read())
                    
    print(f" Контекст успешно собран в {os.path.relpath(out_path, BASE)}.")
    print("Включены файлы:")
    for f in files_to_combine:
        if os.path.exists(f):
            print(f" - {os.path.relpath(f, BASE)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Сборка релевантного контекста для AI")
    parser.add_argument("--project", "-p", help="Имя активного проекта (напр. jf-1c, medev)", default=None)
    args = parser.parse_args()
    
    combine(args.project)
