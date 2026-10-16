"""Exact fixed-point reference for the bounded C# Jaro-Winkler distance contract."""

MAX_STRING_LENGTH = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_STRING_LENGTH
SCALE = 1_000_000_000
INVALID_RESULT = -1


def _parse(values):
    if not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None

    first_length = values[0]
    if not 0 <= first_length <= MAX_STRING_LENGTH:
        return None
    second_length_index = 1 + first_length
    if second_length_index >= len(values):
        return None
    second_length = values[second_length_index]
    if not 0 <= second_length <= MAX_STRING_LENGTH or first_length < second_length:
        return None
    if len(values) != second_length_index + 1 + second_length:
        return None

    first = values[1:second_length_index]
    second = values[second_length_index + 1 :]
    if any(not 0 <= value <= 127 for value in (*first, *second)):
        return None
    return first, second


def expected_result(values):
    """Return fixed-point distance, or -1 for malformed or out-of-contract input."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT
    first, second = parsed
    first_length, second_length = len(first), len(second)

    if first == second:
        return 0
    if second_length == 0:
        return SCALE

    radius = max(first_length // 2 - 1, 0)
    first_matched = [False] * first_length
    second_matched = [False] * second_length
    match_count = 0

    for i, codepoint in enumerate(first):
        start = max(i - radius, 0)
        end = min(i + radius, second_length - 1)
        for j in range(start, end + 1):
            if codepoint == second[j] and not second_matched[j]:
                first_matched[i] = True
                second_matched[j] = True
                match_count += 1
                break

    if match_count == 0:
        return SCALE

    second_index = 0
    mismatched_pairs = 0
    for i, was_matched in enumerate(first_matched):
        if not was_matched:
            continue
        while not second_matched[second_index]:
            second_index += 1
        if first[i] != second[second_index]:
            mismatched_pairs += 1
        second_index += 1
    transpositions = mismatched_pairs // 2

    # J = (m / n1 + m / n2 + (m - t) / m) / 3.
    jaro_numerator = (
        match_count * match_count * second_length
        + match_count * match_count * first_length
        + (match_count - transpositions) * first_length * second_length
    )
    jaro_denominator = 3 * first_length * second_length * match_count

    prefix_length = 0
    for i in range(min(first_length, second_length, 4)):
        if first[i] != second[i]:
            break
        prefix_length += 1

    # Distance = (10 - p) * (1 - J) / 10.
    numerator = (10 - prefix_length) * (jaro_denominator - jaro_numerator)
    denominator = 10 * jaro_denominator
    return (numerator * SCALE + denominator // 2) // denominator
