"""Bounded clean-room K3 SA/PSV/NSV LPF factorization reference."""

import struct

MAX_TEXT_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 16 * MAX_TEXT_LENGTH
LITERAL_SOURCE = -1


def _valid(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if not isinstance(values, (tuple, list)):
        return None
    if input_length is not None and input_length != len(values):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    if any(type(value) is not int or not 0 <= value <= 255 for value in values[1:]):
        return None
    return values[1:]


def factor_pairs_sa_psv_nsv(text):
    n = len(text)
    suffixes = list(range(n))

    def suffix_less(a, b):
        while a < n and b < n:
            if text[a] != text[b]:
                return text[a] < text[b]
            a += 1
            b += 1
        return a == n and b != n

    # Bounded deterministic comparison sort for the suffix array.
    for i in range(1, n):
        value = suffixes[i]
        j = i
        while j > 0 and suffix_less(value, suffixes[j - 1]):
            suffixes[j] = suffixes[j - 1]
            j -= 1
        suffixes[j] = value

    inverse = [0] * n
    for rank, start in enumerate(suffixes):
        inverse[start] = rank

    # For each text start x, find its previous/next strictly smaller SA value.
    previous = [-1] * n
    stack = []
    for rank, start in enumerate(suffixes):
        while stack and suffixes[stack[-1]] > start:
            stack.pop()
        if stack:
            previous[rank] = stack[-1]
        stack.append(rank)

    following = [-1] * n
    stack.clear()
    for rank in range(n - 1, -1, -1):
        start = suffixes[rank]
        while stack and suffixes[stack[-1]] > start:
            stack.pop()
        if stack:
            following[rank] = stack[-1]
        stack.append(rank)

    def lcp(source, target):
        if source < 0:
            return 0
        length = 0
        while target + length < n and text[source + length] == text[target + length]:
            length += 1
        return length

    result = []
    pos = 0
    while pos < n:
        rank = inverse[pos]
        psv = suffixes[previous[rank]] if previous[rank] >= 0 else -1
        nsv = suffixes[following[rank]] if following[rank] >= 0 else -1
        psv_length = lcp(psv, pos)
        nsv_length = lcp(nsv, pos)
        if nsv_length > psv_length:
            source, length = nsv, nsv_length
        else:
            source, length = psv, psv_length  # PSV wins equal-LCP ties.
        if length == 0:
            source = LITERAL_SOURCE
        result.append((source, length))
        pos += max(length, 1)
    return result


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    text = _valid(values, input_is_null, input_length)
    if text is None:
        return -1, b""
    pairs = factor_pairs_sa_psv_nsv(text)
    payload = b"".join(struct.pack("<q", field)
                       for pair in pairs for field in pair)
    if output_is_null or (capacity is not None and
                          (type(capacity) is not int or capacity < len(payload))):
        return -2, b""
    return len(payload), payload

