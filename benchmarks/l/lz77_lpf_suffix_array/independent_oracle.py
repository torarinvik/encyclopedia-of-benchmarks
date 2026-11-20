"""Direct prior-suffix enumeration oracle, independent of SA/stack construction."""

import struct

from .primary_oracle import LITERAL_SOURCE, MAX_OUTPUT_BYTES, _valid


def factor_pairs_direct(text):
    n = len(text)

    def suffix_less(a, b):
        while a < n and b < n:
            if text[a] != text[b]:
                return text[a] < text[b]
            a += 1
            b += 1
        return a == n and b != n

    def lcp(source, target):
        length = 0
        while target + length < n and text[source + length] == text[target + length]:
            length += 1
        return length

    result = []
    pos = 0
    while pos < n:
        # Enumerate all earlier starts and directly locate their closest
        # lexicographic suffix below and above suffix_pos.
        psv = -1
        nsv = -1
        for source in range(pos):
            if suffix_less(source, pos):
                if psv < 0 or suffix_less(psv, source):
                    psv = source
            elif suffix_less(pos, source):
                if nsv < 0 or suffix_less(source, nsv):
                    nsv = source
        psv_length = lcp(psv, pos) if psv >= 0 else 0
        nsv_length = lcp(nsv, pos) if nsv >= 0 else 0
        if nsv_length > psv_length:
            source, length = nsv, nsv_length
        else:
            source, length = psv, psv_length
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
    pairs = factor_pairs_direct(text)
    payload = b"".join(struct.pack("<q", field)
                       for pair in pairs for field in pair)
    if output_is_null or (capacity is not None and
                          (type(capacity) is not int or capacity < len(payload))):
        return -2, b""
    return len(payload), payload

