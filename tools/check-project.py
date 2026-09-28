#!/usr/bin/env python3
"""Validate the portable inputs expected by the generic BB10 build wrapper."""

from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    project = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    cmake_file = project / "CMakeLists.txt"
    if not cmake_file.is_file():
        fail(f"missing CMakeLists.txt in {project}")

    descriptor_path = project / "bar-descriptor.xml"
    app_id = "(no BAR packaging)"
    if descriptor_path.exists():
        try:
            descriptor = ET.parse(descriptor_path).getroot()
        except ET.ParseError as error:
            fail(f"bar-descriptor.xml is not valid XML: {error}")

        namespace = {"qnx": "http://www.qnx.com/schemas/application/1.0"}
        app_id = descriptor.findtext("qnx:id", namespaces=namespace) or ""
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.]+", app_id):
            fail("bar-descriptor.xml has an invalid application id")
        if not descriptor.findall(".//qnx:asset[@entry='true']", namespace):
            fail("bar-descriptor.xml contains no executable entry asset")

    print(f"ok: {project.name} CMake project {app_id}")


if __name__ == "__main__":
    main()
