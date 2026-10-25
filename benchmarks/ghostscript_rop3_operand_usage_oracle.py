"""Independent truth-table oracle for Ghostscript's ROP3 usage macros."""

MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def expected_result(values):
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH or len(values) != 1:
        return INVALID_RESULT
    code = values[0]
    if type(code) is not int or not 0 <= code <= 255:
        return INVALID_RESULT
    depends = 0
    for dimension, flag in ((0, 1), (1, 2), (2, 4)):
        if any(((code >> index) & 1) != ((code >> (index ^ (1 << dimension))) & 1)
               for index in range(8) if not (index & (1 << dimension))):
            depends |= flag
    return depends
