"""Independent printable-ASCII n-gram oracle."""
MAX_INPUT_LENGTH = 258

def expected_output(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    width, text_length = values[:2]
    if type(width) is not int or type(text_length) is not int or not 1 <= width <= 16 or not 0 <= text_length <= 256 or len(values) != text_length + 2:
        return -1, b""
    chars = values[2:]
    if any(type(c) is not int or not 32 <= c <= 126 for c in chars):
        return -1, b""
    windows = [bytes(chars[i:i + width]) for i in range(max(0, text_length - width + 1))]
    output = b"\n".join(windows)
    return len(output), output
