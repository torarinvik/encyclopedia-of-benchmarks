"""Independent oracle for the bounded Java MRU cache benchmark."""

from __future__ import annotations

MAX_OPERATIONS = 128
MAX_CAPACITY = 16
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS + 1
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
MAX_VALUE = 1_000_000
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MISSING_VALUE = -1


def _fnv1a_get_results(responses: list[int]) -> int:
    """Hash get-count:u16-le followed by signed-i32 responses in call order."""
    payload = bytearray(len(responses).to_bytes(2, "little", signed=False))
    for response in responses:
        payload.extend(response.to_bytes(4, "little", signed=True))

    digest = FNV_OFFSET
    for byte in payload:
        digest = ((digest ^ byte) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Run a cache trace and return its response hash, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1

    capacity, count = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 0 <= count <= MAX_OPERATIONS:
        return -1
    if len(values) != 2 + 3 * count:
        return -1

    cache: dict[int, int] = {}
    order: list[int] = []  # oldest at index 0, most recently used at the end
    responses: list[int] = []

    for index in range(count):
        operation, key, value = values[2 + 3 * index : 5 + 3 * index]
        if operation not in (0, 1) or not INT32_MIN <= key <= INT32_MAX:
            return -1
        if not INT32_MIN <= value <= INT32_MAX:
            return -1

        if operation == 0:
            if not 0 <= value <= MAX_VALUE:
                return -1
            if key in cache:
                cache[key] = value
                order.remove(key)
                order.append(key)
            else:
                if len(cache) == capacity:
                    evicted = order.pop()  # pinned implementation evicts the MRU tail
                    del cache[evicted]
                cache[key] = value
                order.append(key)
        else:
            if key not in cache:
                responses.append(MISSING_VALUE)
            else:
                responses.append(cache[key])
                order.remove(key)
                order.append(key)

    return _fnv1a_get_results(responses)
