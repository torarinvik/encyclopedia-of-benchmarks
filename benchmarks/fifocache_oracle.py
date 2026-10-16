"""Runtime oracle for deterministic FIFO cache put/get traces."""

MAX_CAPACITY = 6
MAX_OPERATIONS = 8
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 4 + MAX_OPERATIONS + 2 * MAX_CAPACITY


def expected_output(values, output_capacity=None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    capacity, operation_count = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    if len(values) != 2 + 3 * operation_count:
        return -1, b""
    cache = []
    hits = misses = 0
    query_results = []
    for index in range(operation_count):
        operation, key, value = values[2 + 3 * index: 5 + 3 * index]
        if operation not in (0, 1) or not 0 <= key <= 15:
            return -1, b""
        if operation == 0:
            if not 0 <= value <= 255:
                return -1, b""
            cache = [(old_key, old_value) for old_key, old_value in cache if old_key != key]
            if len(cache) == capacity:
                cache.pop(0)
            cache.append((key, value))
        else:
            if value != 0:
                return -1, b""
            found = next((cached_value for cached_key, cached_value in cache if cached_key == key), None)
            if found is None:
                misses += 1
                query_results.append(255)
            else:
                hits += 1
                query_results.append(found)
    output = bytes([hits, misses, len(cache), len(query_results), *query_results,
                    *(part for pair in cache for part in pair)])
    if output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output
