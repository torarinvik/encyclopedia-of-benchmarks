"""Runtime oracle for the pinned Java ASCII phonetic alphabet conversion."""
MAX_INPUT_LENGTH = 65
MAX_TEXT_BYTES = 64
MAX_OUTPUT_BYTES = 575
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
WORDS = (
    "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett",
    "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango",
    "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu",
    "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
)
WHITESPACE = {9, 10, 11, 12, 13, 32}


def expected_output(values):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(x) is not int for x in values):
        return INVALID_RESULT, b""
    count, chars = values[0], values[1:]
    if not 0 <= count <= MAX_TEXT_BYTES or len(chars) != count or any(not (x in WHITESPACE or 33 <= x <= 126) for x in chars):
        return INVALID_RESULT, b""
    words = []
    for code in chars:
        if code in WHITESPACE:
            continue
        if 97 <= code <= 122:
            code -= 32
        if 65 <= code <= 90:
            words.append(WORDS[code - 65].encode("ascii"))
        elif 48 <= code <= 57:
            words.append(WORDS[26 + code - 48].encode("ascii"))
        else:
            words.append(bytes((code,)))
    output = b" ".join(words)
    return len(output), output
