"""Independent oracle for the source-compatible ASCII UChar lowercase helper."""
from __future__ import annotations

MAX_CHARACTERS = 31
MAX_OUTPUT_BYTES = 1 + 2 * MAX_CHARACTERS
MAX_PARSEABLE_INPUT_LENGTH = MAX_CHARACTERS + 2
OUTPUT_ERROR = -2


def expected_output(values: list[int]) -> tuple[int, bytes]:
    """Return the ASCII flag and mapped UTF-16LE code units."""
    if (type(values) is not list or not 1 <= len(values) <= MAX_CHARACTERS + 2
            or type(values[0]) is not int):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_CHARACTERS or len(values) != count + 1:
        return -1, b""
    units: list[int] = []
    for raw in values[1:]:
        if type(raw) is not int or not 0 <= raw <= 0xFFFF:
            return -1, b""
        units.append(raw)
    ascii_flag = int(all(unit <= 0x7F for unit in units))
    lowered = [unit + 0x20 if 0x41 <= unit <= 0x5A else unit for unit in units]
    output = bytes((ascii_flag,)) + b"".join(unit.to_bytes(2, "little") for unit in lowered)
    return len(output), output
