"""Independent oracle for the bounded FreeBench pcompress2 compression core."""

from __future__ import annotations

from typing import Sequence

MAX_LENGTH = 32
MAX_OUTPUT_BYTES = 8 + MAX_LENGTH * 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _arithmetic_encode(data: bytes) -> bytes:
    # Adaptive 257-symbol model: byte values are 0..255 and EOF is symbol 257.
    char_to_index = [i + 1 for i in range(256)]
    index_to_char = [0] * 258
    for i in range(256):
        index_to_char[i + 1] = i
    freq = [1] * 258
    freq[0] = 0
    cum = [257 - i for i in range(258)]
    buffer = 0
    bits_to_go = 8
    encoded = bytearray()
    low, high, follow = 0, 65535, 0

    def output_bit(bit: int) -> None:
        nonlocal buffer, bits_to_go
        buffer >>= 1
        if bit:
            buffer |= 0x80
        bits_to_go -= 1
        if bits_to_go == 0:
            encoded.append(buffer)
            bits_to_go = 8

    def bit_plus_follow(bit: int) -> None:
        nonlocal follow
        output_bit(bit)
        while follow > 0:
            output_bit(1 - bit)
            follow -= 1

    def encode_symbol(symbol: int) -> None:
        nonlocal low, high
        span = high - low + 1
        old_low = low
        high = old_low + span * cum[symbol - 1] // cum[0] - 1
        low = old_low + span * cum[symbol] // cum[0]
        while True:
            if high < 32768:
                bit_plus_follow(0)
            elif low >= 32768:
                bit_plus_follow(1)
                low -= 32768
                high -= 32768
            elif low >= 16384 and high < 49152:
                follow += 1
                low -= 16384
                high -= 16384
            else:
                break
            low *= 2
            high = high * 2 + 1

    def update_model(symbol: int) -> None:
        nonlocal freq, cum
        if cum[0] == 16383:
            total = 0
            for i in range(257, -1, -1):
                freq[i] = (freq[i] + 1) // 2
                cum[i] = total
                total += freq[i]
        index = symbol
        while freq[index] == freq[index - 1]:
            index -= 1
        if index < symbol:
            old_index_char = index_to_char[index]
            old_symbol_char = index_to_char[symbol]
            index_to_char[index], index_to_char[symbol] = old_symbol_char, old_index_char
            char_to_index[old_index_char] = symbol
            char_to_index[old_symbol_char] = index
        freq[index] += 1
        for i in range(index - 1, -1, -1):
            cum[i] += 1

    for value in data:
        symbol = char_to_index[value]
        encode_symbol(symbol)
        update_model(symbol)
    encode_symbol(257)
    follow += 1
    bit_plus_follow(0 if low < 16384 else 1)
    encoded.append(buffer >> bits_to_go)
    return bytes(encoded)


def _encode(source: bytes) -> bytes:
    n = len(source)
    order = list(range(n))

    def rotation_key(start: int) -> tuple[bytes, int]:
        return source[start:] + source[:start], start

    order.sort(key=rotation_key)
    primary = order.index(0)
    last = bytes(source[(start + n - 1) % n] for start in order)

    rle = bytearray()
    position = 0
    while position < n:
        count = 1
        value = last[position]
        while position + count < n and last[position + count] == value and count < 127:
            count += 1
        if count == 1:
            while (position + count < n
                   and last[position + count - 1] != last[position + count]
                   and (position + count + 1 == n
                        or last[position + count] != last[position + count + 1])):
                count += 1
            rle.append(count & 0x7F)
            rle.extend(last[position:position + count])
            position += count
        else:
            rle.extend((count | 0x80, value))
            position += count

    return (n.to_bytes(4, "little") + primary.to_bytes(4, "little")
            + _arithmetic_encode(bytes(rle)))


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or values is None or not 2 <= len(values) <= MAX_LENGTH + 1
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_LENGTH or len(values) != n + 1:
        return -1, b""
    if any(value < 0 or value > 255 for value in values[1:]):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    encoded = _encode(bytes(values[1:]))
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
