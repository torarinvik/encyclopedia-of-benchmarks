"""Oracle for the bounded NBench Huffman compression/decode kernel."""
from __future__ import annotations
import struct
from typing import Sequence

MAX_TEXT = 128
NODE_COUNT = 512
EXCLUDED = 32000
MAX_INPUT_LENGTH = MAX_TEXT + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 262
INVALID_RESULT = -1
OUTPUT_ERROR = -2

def _f32(x: float) -> float:
    return struct.unpack("<f", struct.pack("<f", x))[0]

def _encode(payload: list[int]) -> tuple[int, bytes] | None:
    # NBench's arraysize includes a terminating NUL. Preserve that in the tree and stream.
    text = payload + [0]
    n = len(text)
    freq = [0.0] * NODE_COUNT
    chars = list(range(256)) + [0] * 256
    parent = [-1] * NODE_COUNT
    left = [-1] * NODE_COUNT
    right = [-1] * NODE_COUNT
    for ch in text:
        freq[ch] = _f32(freq[ch] + _f32(1.0))
    for i in range(256):
        if freq[i] != 0.0:
            freq[i] = _f32(freq[i] / _f32(float(n)))
    for i in range(NODE_COUNT):
        if freq[i] == 0.0:
            parent[i] = EXCLUDED
        else:
            parent[i] = -1
            left[i] = right[i] = -1
    root = 255
    while True:
        low1 = low2 = 2.0
        idx1 = idx2 = -1
        for i in range(root + 1):
            if parent[i] < 0 and freq[i] < low1:
                low1, idx1 = freq[i], i
        if idx1 < 0:
            break
        for i in range(root + 1):
            if parent[i] < 0 and i != idx1 and freq[i] < low2:
                low2, idx2 = freq[i], i
        if idx2 < 0:
            break
        root += 1
        parent[idx1] = parent[idx2] = root
        freq[root] = _f32(low1 + low2)
        left[root], right[root], parent[root] = idx1, idx2, -2
    if root < 256 or left[root] < 0:
        return None

    bits: list[int] = []
    codes: dict[int, list[int]] = {}
    for ch in range(256):
        if freq[ch] == 0.0:
            continue
        path: list[int] = []
        node = ch
        while parent[node] != -2:
            par = parent[node]
            if par < 0 or par >= NODE_COUNT:
                return None
            path.append(0 if left[par] == node else 1)
            node = par
        codes[ch] = list(reversed(path))
    for ch in text:
        bits.extend(codes[ch])
    stream = bytearray((len(bits) + 7) // 8)
    for offset, bit in enumerate(bits):
        if bit:
            stream[offset >> 3] |= 1 << (offset & 7)
    decoded: list[int] = []
    offset = 0
    while offset < len(bits):
        node = root
        while left[node] != -1:
            bit = (stream[offset >> 3] >> (offset & 7)) & 1
            node = right[node] if bit else left[node]
            offset += 1
            if offset > len(bits):
                return None
        decoded.append(chars[node])
    if decoded != text:
        return None
    return len(bits), bytes(stream)

def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values):
        return INVALID_RESULT, b""
    n = values[0]
    if n < 1 or n > MAX_TEXT or len(values) != n + 1 or any(ch < 32 or ch > 47 for ch in values[1:]):
        return INVALID_RESULT, b""
    if len(set(values[1:]) | {0}) < 2:
        return INVALID_RESULT, b""
    packed = _encode(list(values[1:]))
    if packed is None:
        return INVALID_RESULT, b""
    bits, stream = packed
    output = struct.pack("<I", bits) + stream
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if output_is_null or capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
