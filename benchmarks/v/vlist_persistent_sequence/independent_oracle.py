"""Independent tuple-version interpreter for the VList operation contract."""

import struct

BAD = -1
NO_OUTPUT = -2
Q_LIMIT = 48
VALUE_LIMIT = 1_000_000
WORD_LIMIT = 146
OUTPUT_LIMIT = 384


def _parse(data, length, null):
    if (type(null) is not bool or null or not isinstance(data, (list, tuple))
            or not 1 <= len(data) <= WORD_LIMIT
            or any(type(v) is not int or v < -(1 << 63) or v >= 1 << 63 for v in data)
            or length is not None and (type(length) is not int or length != len(data))):
        return None
    q = data[0]
    if not 1 <= q <= Q_LIMIT or len(data) != 1 + 3 * q:
        return None
    return q


def _run(data, input_length, input_is_null):
    q = _parse(data, input_length, input_is_null)
    if q is None:
        return None
    versions = [()]
    result = []
    building = True
    cons_count = 0
    offset = 1
    for _ in range(q):
        tag, source_id, arg = data[offset:offset + 3]
        offset += 3
        if not 0 <= source_id < len(versions):
            return None
        source = versions[source_id]
        if tag == 0:
            if (not building or source_id != len(versions) - 1 or cons_count >= 32
                    or not -VALUE_LIMIT <= arg <= VALUE_LIMIT):
                return None
            current = (arg,) + source
            versions.append(current)
            result.append(len(versions) - 1)
            cons_count += 1
        else:
            building = False
            if tag == 1:
                if arg != -1 or not source:
                    return None
                versions.append(source[1:])
                result.append(len(versions) - 1)
            elif tag == 2:
                if type(arg) is not int or not 0 <= arg < len(source):
                    return None
                result.append(source[arg])
            elif tag == 3:
                if arg != -1:
                    return None
                result.append(len(source))
            else:
                return None
    return result


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _run(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", x) for x in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
