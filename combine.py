import os
import glob

dirs = [
    r"C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain\projects\sklad",
    r"C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain\projects\career-hub",
    r"C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain\projects\envie"
]

with open(r"C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain\combined_docs.md", "w", encoding="utf-8") as out:
    for d in dirs:
        for f in glob.glob(os.path.join(d, "*.md")):
            out.write(f"\n\n--- {f} ---\n\n")
            with open(f, "r", encoding="utf-8") as infile:
                out.write(infile.read())
