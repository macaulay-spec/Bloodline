"""Reorders top-level definitions in GDScript files to match gdtoolkit's
class-definitions-order rule.

    python3 tools/gdscript/reorder_definitions.py Game/scripts

The rule order is: tools, class_name, extends, class docstring, signals,
enums, constants, static vars, exports, public vars, private vars, onready
public vars, onready private vars, then functions.

Each definition keeps the comment block that documents it. The class
docstring, which sits directly under the `extends` line, stays there.
"""

import os
import re
import sys

ORDER = [
    "tool",
    "class_name",
    "extends",
    "docstring",
    "signal",
    "enum",
    "const",
    "staticvar",
    "export",
    "pubvar",
    "prvvar",
    "onreadypubvar",
    "onreadyprvvar",
    "other",
]

DEFINITION = re.compile(
    r"^(tool|class_name|extends|signal|enum|const|static var|@export|var|func)\b")


def categorize(text: str) -> str:
    """Classifies a definition by its first non-comment line."""
    stripped = ""
    for line in text.split("\n"):
        candidate = line.strip()
        if not candidate or candidate.startswith("#"):
            continue
        stripped = candidate
        break
    if not stripped:
        return "other"
    if stripped.startswith("@tool"):
        return "tool"
    if stripped.startswith("class_name"):
        return "class_name"
    if stripped.startswith("extends"):
        return "extends"
    if stripped.startswith("signal "):
        return "signal"
    if stripped.startswith("enum "):
        return "enum"
    if stripped.startswith("const "):
        return "const"
    if stripped.startswith("static var "):
        return "staticvar"
    if stripped.startswith("@export"):
        return "export"
    if stripped.startswith("var "):
        name = stripped.split(":", 1)[0].strip()[4:].strip()
        if name.startswith("_"):
            return "prvvar"
        return "pubvar"
    return "other"


def split_into_blocks(lines):
    """Splits the file into (kind, text) blocks.

    A block is a run of top-level definition lines plus the comment lines
    that immediately precede them, so documentation travels with the
    definition it describes.
    """
    starts = [index for index, line in enumerate(lines) if DEFINITION.match(line)]

    # For each definition, find the comment block that documents it.
    doc_starts = []
    for start in starts:
        cut = start
        while cut > 0 and lines[cut - 1].strip().startswith("#"):
            cut -= 1
        doc_starts.append(cut)

    # The class docstring sits between the `extends` line and the first
    # definition. It documents the class, not the first member, so it is
    # pulled out separately.
    class_docstring = None
    extends_index = None
    for index, line in enumerate(lines):
        if line.startswith("extends "):
            extends_index = index
            break
    if extends_index is not None and starts:
        between = lines[extends_index + 1:starts[0]]
        if between and all(line.strip().startswith("##") for line in between if line.strip()):
            class_docstring = "\n".join(between).strip()
            doc_starts[0] = starts[0]

    result = []
    for position, start in enumerate(starts):
        block_start = doc_starts[position]
        # The block runs to the start of the next definition's comments.
        block_end = doc_starts[position + 1] if position + 1 < len(starts) \
            else len(lines)
        text = "\n".join(lines[block_start:block_end]).rstrip()
        if text:
            result.append((categorize(text), text, block_start))

    return result, class_docstring


def reorder(path: str) -> bool:
    with open(path, "r", encoding="utf-8") as handle:
        original = handle.read()

    lines = original.split("\n")
    blocks, docstring = split_into_blocks(lines)
    if not blocks:
        return False

    # Stable sort by the rule order.
    blocks.sort(key=lambda item: ORDER.index(item[0]))

    out = []
    for kind, text, _start in blocks:
        if kind == "extends" and docstring:
            out.append(text)
            out.append("")
            out.append(docstring)
            docstring = None
        else:
            out.append(text)
            out.append("")

    # Drop a leading docstring that was not attached to the extends line.
    if docstring:
        out.insert(0, docstring)
        out.insert(1, "")

    result = "\n".join(out)
    result = re.sub(r"\n{3,}", "\n\n", result).rstrip() + "\n"

    if result == original:
        return False
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(result)
    return True


def main() -> int:
    roots = sys.argv[1:] or ["Game/scripts"]
    changed = 0
    for root in roots:
        for directory, _dirs, files in os.walk(root):
            for name in sorted(files):
                if name.endswith(".gd"):
                    path = os.path.join(directory, name)
                    if reorder(path):
                        print("reordered", path)
                        changed += 1
    print("%d file(s) reordered" % changed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
