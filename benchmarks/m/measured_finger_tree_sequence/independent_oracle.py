"""Independent tuple-version model for the measured finger-tree workload."""
import struct

BAD = -1
NO_OUTPUT = -2
MAX_WORDS = 195
MAX_COUNT = 32
MAX_VALUE = 1_000_000
MAX_LENGTH = 64
MAX_TOTAL = 64_000_000


def _parse(data, length, null):
    if (type(null) is not bool or null or not isinstance(data, (tuple, list))
            or not 1 <= len(data) <= MAX_WORDS
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in data)
            or length is not None and (type(length) is not int or length != len(data))):
        return None
    n = data[0]
    if not 0 <= n <= MAX_COUNT or len(data) < n + 2:
        return None
    initial = tuple(data[1:n+1])
    if any(not 0 <= v <= MAX_VALUE for v in initial):
        return None
    q = data[n+1]
    if not 1 <= q <= MAX_COUNT or len(data) != n + 2 + 5*q:
        return None
    return initial, q


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return BAD, b""
    initial, q = parsed
    versions = [initial]
    records = []
    cursor = len(initial) + 2
    for _ in range(q):
        tag, first, second, arg, extra = values[cursor:cursor+5]
        cursor += 5
        if tag < 0 or tag > 6 or first < 0 or first >= len(versions):
            return BAD, b""
        source = versions[first]
        aux = -1
        second_id = -1
        if tag == 0 or tag == 1:
            if second != -1 or extra != -1 or not 0 <= arg <= MAX_VALUE or len(source) == MAX_LENGTH:
                return BAD, b""
            value_list = [arg, *source] if tag == 0 else [*source, arg]
            if sum(value_list) > MAX_TOTAL:
                return BAD, b""
            versions.append(tuple(value_list))
            result_id = len(versions)-1
            result = versions[result_id]
        elif tag == 2 or tag == 3:
            if second != -1 or arg != -1 or extra != -1 or not source:
                return BAD, b""
            aux = source[0] if tag == 2 else source[-1]
            versions.append(source[1:] if tag == 2 else source[:-1])
            result_id = len(versions)-1
            result = versions[result_id]
        elif tag == 4:
            if second < 0 or second >= len(versions) or arg != -1 or extra != -1:
                return BAD, b""
            value_list = [*source, *versions[second]]
            if len(value_list) > MAX_LENGTH or sum(value_list) > MAX_TOTAL:
                return BAD, b""
            versions.append(tuple(value_list))
            result_id = len(versions)-1
            result = versions[result_id]
        else:
            if second != -1 or extra != -1:
                return BAD, b""
            if tag == 5:
                if arg < 0 or arg > len(source):
                    return BAD, b""
                cut = arg
                aux = cut
            else:
                if arg < 1 or arg > MAX_TOTAL:
                    return BAD, b""
                running = 0
                cut = len(source)
                found = False
                for index, value in enumerate(source, 1):
                    running += value
                    if running >= arg:
                        cut = index
                        aux = cut
                        found = True
                        break
                if not found:
                    aux = -1
            left = tuple(source[:cut])
            right = tuple(source[cut:])
            versions.extend((left, right))
            result_id = len(versions)-2
            second_id = len(versions)-1
            result = versions[result_id]
        records.extend((result_id, len(result), sum(result), second_id,
                        len(versions[second_id]) if second_id >= 0 else -1,
                        sum(versions[second_id]) if second_id >= 0 else -1,
                        aux))
    payload = b"".join(struct.pack("<q", x) for x in records)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
