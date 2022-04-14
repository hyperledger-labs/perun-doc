import os
import re

from six.moves import urllib


def gen_link(rst_file, li):
    """
    Generates a github link to code referenced by an rst literalinclude

    :param rst_file: lines of rst file
    :param li: index of literalinclude
    :return: github link if literalinclude covers code block with keyword, otherwise None
    """
    # Get code file path and gen raw url.
    code_path = rst_file[li].split(repository_name)[1].replace("\n", "")
    raw_url = gh_raw_url + code_path

    # Extract line numbers (that will be checked for keywords).
    start = -1
    end = -1
    for n in range(li, li + 5):
        if ":lines:" in rst_file[n]:
            lines = re.findall('[0-9]+', rst_file[n])
            start = int(lines[0]) - 1
            end = int(lines[1])
            break

    if start == -1 or end == -1:
        return None  # No line numbers.

    # Find func, type or const in code.
    code = urllib.request.urlopen(raw_url).readlines()

    line = -1
    for p in range(start, end):
        code_line = str(code[p])
        # Check for keywords.
        if code_line.__contains__("func") or code_line.__contains__("type") or code_line.__contains__("contract"):
            line = p
            break

    if line >= 0:
        caption = base_url + code_path + "#L" + str(
            line + 1)  # Lines begin with 1, therefore correct offset here with + 1.
        return caption
    else:
        return None  # No keywords detected.


def manipulate_rst_file(path):
    """
    Manipulates a single rst file

    :param path: path to rst file
    """
    print("Manipulating literalincludes in " + path + " ...")
    # open rst file
    with open(path, 'r') as file:
        # read a list of lines into data.
        rst_data = file.readlines()

    # Find literalincludes and generate links.
    links = []  # Stored as (number of line, content).
    for i in range(len(rst_data)):
        if rst_data[i].startswith(".. literalinclude::"):
            link = gen_link(rst_data, i)
            links.append((i, link))

    # Insert into rst file
    added_line_offset = 1  # compensate added lines - start from 1 to paste under literalinclude.
    for l in links:
        index = l[0] + added_line_offset
        link = l[1]
        if link is not None:
            caption = CAPTION_TEXT.replace("link", link)

            # Prepend blanks to caption (to be in line with other arguments).
            spaces = rst_data[index].split(":")[0].count(" ")
            caption = " " * spaces + caption

            # Look for existing caption and overwrite if user desires.
            overwritten = False
            caption_found = False
            end = index + 5  # Define area
            if end > len(rst_data):
                end = len(rst_data)
            for n in range(index, end):
                if ":caption:" in rst_data[n]:
                    caption_found = True
                    if overwrite_captions:
                        rst_data[n] = caption
                        print("Updated caption in line " + str(n + 1) + " ...")
                        overwritten = True

            if not overwritten and not caption_found:
                rst_data.insert(index, caption)
                print("Added caption to line " + str(index + 1) + " ...")
                added_line_offset += 1
            elif caption_found and not overwrite_captions:
                print("Skipped line " + str(index + 1) + " (do not overwrite) ...")
        else:
            print("Skipped line " + str(index + 1) + " (no keyword or line numbers found here) ...")

    with open(path, 'w') as file:
        file.writelines(rst_data)

    print("\n")


if __name__ == "__main__":
    CAPTION_TEXT = ":caption: `👇 This code on GitHub. <link>`__\n"

    base_url = str(input("Enter repository link with commit hash (e.g. "
                         "https://github.com/perun-network/perun-examples/blob"
                         "/689b8cdfef8ef8fb527723d52e6ce36dfe1b661c)\n"))
    if "blob" not in base_url:
        raise ValueError("Repository link invalid.")

    rst_path = str(input("Enter absolute path to .rst file or folder with .rst files (e.g. "
                         "/Users/lr/Documents/Repos/perun-doc/source/go-perun/app_tutorial)\n"))
    if not os.path.exists(rst_path):
        raise FileExistsError("Folder or file not found.")

    overwrite_captions = input("Do you want to overwrite existing captions? (N)o / (Y)es\n")
    if overwrite_captions.lower() == "y":
        overwrite_captions = True
    elif overwrite_captions.lower() == "n":
        overwrite_captions = False
    else:
        raise ValueError("Please input Y or N")

    # Prepare GitHub raw url.
    gh_raw_url = base_url.replace("github.com", "raw.githubusercontent.com").replace("/blob", "")

    # Extract repository name.
    repository_name = ""
    split_blob = base_url.split("/")
    for sp in range(len(split_blob)):
        if split_blob[sp] == "blob":
            repository_name = split_blob[sp - 1]

    # Check if file or folder is given and execute manipulation.
    if rst_path.endswith(".rst"):
        manipulate_rst_file(rst_path)
    else:
        for root, dirs, files in os.walk(rst_path):  # Walk through folder.
            for file in files:
                file_path = os.path.join(root, file)
                if file_path.endswith(".rst"):  # Only consider .rst files.
                    manipulate_rst_file(file_path)
