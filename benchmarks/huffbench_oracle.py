"""Independent reference model for the bounded LAC-DCC Huffbench profile."""

from __future__ import annotations

MIN_PASSES = 1
MAX_PASSES = 30
DATA_BYTES = 4096
MASK = 123459876
IA = 16807
IM = 2147483647
IQ = 127773
IR = 2836
ALPHABET = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"


def _generated_data() -> bytes:
    seed = 1325
    result = bytearray(DATA_BYTES)
    for index in range(DATA_BYTES):
        seed ^= MASK
        quotient = seed // IQ
        seed = IA * (seed - quotient * IQ) - IR * quotient
        if seed < 0:
            seed += IM
        result[index] = ALPHABET[seed % 32]
        seed ^= MASK
    return bytes(result)


def _heap_adjust(frequencies: list[int], heap: list[int], active: int, one_based: int) -> None:
    value = heap[one_based - 1]
    index = one_based
    while index <= active // 2:
        child = index * 2
        if child < active and frequencies[heap[child - 1]] > frequencies[heap[child]]:
            child += 1
        if frequencies[value] < frequencies[heap[child - 1]]:
            break
        heap[index - 1] = heap[child - 1]
        index = child
    heap[index - 1] = value


def _compressed_length(data: bytes) -> int:
    frequencies = [0] * 512
    for byte in data:
        frequencies[byte] += 1
    heap = [byte for byte in range(256) if frequencies[byte] != 0]
    active = len(heap)
    for index in range(active, 0, -1):
        _heap_adjust(frequencies, heap, active, index)
    links = [0] * 512
    while active > 1:
        active -= 1
        first = heap[0]
        heap[0] = heap[active]
        _heap_adjust(frequencies, heap, active, 1)
        parent = 256 + active
        frequencies[parent] = frequencies[heap[0]] + frequencies[first]
        links[first] = parent
        links[heap[0]] = -parent
        heap[0] = parent
        _heap_adjust(frequencies, heap, active, 1)
    links[256 + active] = 0

    total_bits = 0
    for symbol in range(256):
        if frequencies[symbol] == 0:
            continue
        link = links[symbol]
        depth = 0
        while link != 0:
            if link < 0:
                link = -link
            link = links[link]
            depth += 1
        total_bits += frequencies[symbol] * depth
    return (total_bits + 7) // 8


def expected_output(passes: int) -> bytes | None:
    if passes < MIN_PASSES or passes > MAX_PASSES:
        return None
    data = _generated_data()
    compressed_length = _compressed_length(data)
    checksum = sum(data) & 0xFFFFFFFF
    return f"Huffbench passes={passes} compressed={compressed_length} checksum={checksum}\n".encode("ascii")


def call(passes: int, output_capacity: int, output_is_null: bool = False) -> tuple[int, bytes]:
    expected = expected_output(passes)
    if expected is None:
        return -1, b""
    if output_is_null or output_capacity < len(expected):
        return -2, b""
    return len(expected), expected
