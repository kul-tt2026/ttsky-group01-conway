import sys
import xml.etree.ElementTree as ET

args = sys.argv[1:]
if "-o" in args:
    idx = args.index("-o")
    out_path = args[idx + 1]
    files = args[:idx] + args[idx + 2:]
else:
    out_path = "results.xml"
    files = args

root = ET.Element("testsuites", name="results")
suite = ET.SubElement(root, "testsuite", name="all", package="all")

for f in sorted(files):
    tree = ET.parse(f)
    for ts in tree.getroot().iter("testsuite"):
        for tc in ts.findall("testcase"):
            suite.append(tc)

ET.ElementTree(root).write(out_path, xml_declaration=True, encoding="utf-8")
print(f"Merged {len(files)} files into {out_path}")