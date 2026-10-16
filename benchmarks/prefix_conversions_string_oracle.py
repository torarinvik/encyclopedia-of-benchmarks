"""Oracle for bounded automatic SI/binary prefix formatting."""

MAX_INPUT_LENGTH = 2
MAX_VALUE = 1_000_000_000_000
INVALID_RESULT = -1

SI_PREFIXES = ((9, "giga", 10**9), (6, "mega", 10**6), (3, "kilo", 10**3),
               (2, "hecto", 10**2), (1, "deca", 10))
BINARY_PREFIXES = ((30, "giga", 1 << 30), (20, "mega", 1 << 20),
                   (10, "kilo", 1 << 10))


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT, b""
    mode, value = values
    if mode not in (0, 1) or not -MAX_VALUE <= value <= MAX_VALUE:
        return INVALID_RESULT, b""
    if value <= 0:
        return len(str(value)), str(value).encode("ascii")
    prefixes = SI_PREFIXES if mode == 0 else BINARY_PREFIXES
    for _, name, scale in prefixes:
        if value > scale:
            if value % scale:
                return INVALID_RESULT, b""
            text = f"{value // scale}.0 {name}"
            return len(text), text.encode("ascii")
    text = str(value)
    return len(text), text.encode("ascii")
