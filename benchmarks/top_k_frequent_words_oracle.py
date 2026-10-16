"""Bounded oracle for first-seen frequency counting and max-heap ranking."""

from __future__ import annotations

MAX_WORDS = 64
MAX_WORD_LENGTH = 16
MAX_INPUT_LENGTH = 2 + MAX_WORDS * (MAX_WORD_LENGTH + 1)
MAX_OUTPUT_BYTES = MAX_WORDS * (MAX_WORD_LENGTH + 1) + 1


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    k, word_count = values[:2]
    if not 0 <= k <= MAX_WORDS or not 0 <= word_count <= MAX_WORDS:
        return -1, b""

    position = 2
    frequencies: dict[bytes, int] = {}
    for _ in range(word_count):
        if position >= len(values) or not 1 <= values[position] <= MAX_WORD_LENGTH:
            return -1, b""
        word_length = values[position]
        position += 1
        if word_length > len(values) - position:
            return -1, b""
        word_values = values[position:position + word_length]
        if any(not 97 <= value <= 122 for value in word_values):
            return -1, b""
        word = bytes(word_values)
        frequencies[word] = frequencies.get(word, 0) + 1
        position += word_length
    if position != len(values):
        return -1, b""

    heap = list(frequencies.items())

    def sift_down(root: int, size: int) -> None:
        best = root
        left = 2 * root + 1
        right = left + 1
        if left < size and heap[left][1] > heap[best][1]:
            best = left
        if right < size and heap[right][1] > heap[best][1]:
            best = right
        if best != root:
            heap[root], heap[best] = heap[best], heap[root]
            sift_down(best, size)

    for index in range(len(heap) // 2 - 1, -1, -1):
        sift_down(index, len(heap))

    ranked: list[bytes] = []
    size = len(heap)
    for _ in range(min(k, size)):
        ranked.append(heap[0][0])
        size -= 1
        if size:
            heap[0] = heap[size]
            sift_down(0, size)

    output = b"".join(word + b"\n" for word in ranked) + b"\0"
    if len(output) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
