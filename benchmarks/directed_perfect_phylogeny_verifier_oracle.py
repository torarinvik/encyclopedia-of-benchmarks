"""Independent integer-mask test of the laminar character-set condition."""
MAX_INPUT_LENGTH = 146
MAX_OUTPUT_BYTES = 8


def verify(values):
    if values is None or len(values) < 3 or len(values) > 146:
        return -1, b""
    taxa, chars = values[0], values[1]
    if taxa < 1 or taxa > 12 or chars < 1 or chars > 12 or len(values) != 2 + taxa * chars:
        return -1, b""
    masks = [0] * chars
    for i, bit in enumerate(values[2:]):
        if bit not in (0, 1):
            return -1, b""
        if bit:
            masks[i % chars] |= 1 << (i // chars)
    valid = 1
    for i, x in enumerate(masks):
        for y in masks[i + 1:]:
            if x & y and (x & y) != x and (x & y) != y:
                valid = 0
                break
        if not valid:
            break
    return 8, valid.to_bytes(8, "little", signed=True)
