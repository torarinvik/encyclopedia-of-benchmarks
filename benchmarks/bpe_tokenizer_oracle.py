"""Portable byte-pair encoding oracle for the bounded tokenizer benchmark."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_TEXT_BYTES = 512
MAX_MERGES = 32
MAX_INPUT_LENGTH = MAX_TEXT_BYTES + 3  # permit one oversized invalid payload


def expected_output(values: list[int]) -> tuple[int, bytes]:
    """Return token count and little-endian u16 token IDs, or -2 if malformed."""
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2, b""
    merge_count, byte_count = values[:2]
    if (not 0 <= merge_count <= MAX_MERGES or not 0 <= byte_count <= MAX_TEXT_BYTES
            or len(values) != byte_count + 2
            or any(not 0 <= value <= 255 for value in values[2:])):
        return -2, b""

    tokens = list(values[2:])
    for step in range(min(merge_count, len(tokens) - 1)):
        counts: dict[tuple[int, int], int] = {}
        for pair in zip(tokens, tokens[1:]):
            counts[pair] = counts.get(pair, 0) + 1
        if not counts:
            break
        pair = max(counts, key=counts.__getitem__)
        if counts[pair] == 1:
            break

        merged: list[int] = []
        index = 0
        while index < len(tokens):
            if index + 1 < len(tokens) and (tokens[index], tokens[index + 1]) == pair:
                merged.append(256 + step)
                index += 2
            else:
                merged.append(tokens[index])
                index += 1
        tokens = merged

    output = b"".join(token.to_bytes(2, "little") for token in tokens)
    return len(tokens), output
