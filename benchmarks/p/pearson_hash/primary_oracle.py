"""Primary scalar reference for the bounded Pearson byte-string hash."""

TABLE_SIZE = 256
MAX_TEXT_BYTES = 64
MAX_VALID_INPUT_LENGTH = 1 + TABLE_SIZE + MAX_TEXT_BYTES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_WORKSPACE_BYTES = 1024


def expected_result(values: list[int]) -> int:
    """Hash [text_length, permutation[256], text...] or return -1."""
    if len(values) < 1 + TABLE_SIZE or len(values) > MAX_INPUT_LENGTH:
        return -1

    text_length = values[0]
    if not isinstance(text_length, int) or isinstance(text_length, bool):
        return -1
    if text_length < 0 or text_length > MAX_TEXT_BYTES + 1:
        return -1
    if len(values) != 1 + TABLE_SIZE + text_length:
        return -1
    if text_length > MAX_TEXT_BYTES:
        return -1

    table_values = values[1:1 + TABLE_SIZE]
    if any(not isinstance(value, int) or isinstance(value, bool) or
           value < 0 or value >= TABLE_SIZE for value in table_values):
        return -1
    if len(set(table_values)) != TABLE_SIZE:
        return -1

    text = values[1 + TABLE_SIZE:]
    if any(not isinstance(value, int) or isinstance(value, bool) or
           value < 0 or value > 255 for value in text):
        return -1

    state = 0
    for byte in text:
        state = table_values[state ^ byte]
    return state
