"""Runtime oracle for the pinned normalized feature-map Gram operations."""
import struct

MAX_CHANNELS = 3
MAX_PIXELS = 4
MAX_INPUT_LENGTH = 3 + 2 * MAX_CHANNELS * MAX_PIXELS
MAX_OUTPUT_BYTES = MAX_CHANNELS * MAX_CHANNELS * 8


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    operation, channels, pixels = values[:3]
    if operation not in (0, 1) or not 1 <= channels <= MAX_CHANNELS or not 1 <= pixels <= MAX_PIXELS:
        return -1, b""
    feature_values = channels * pixels
    expected_length = 3 + feature_values * (2 if operation == 1 else 1)
    if len(values) != expected_length:
        return -1, b""
    raw = values[3:]
    if any(x < -1000 or x > 1000 for x in raw):
        return -1, b""
    denominator = float(feature_values)

    def gram(part):
        rows = [[raw[part * feature_values + c * pixels + p] / 1000.0
                 for p in range(pixels)] for c in range(channels)]
        result = []
        for i in range(channels):
            for j in range(channels):
                dot = 0.0
                for p in range(pixels):
                    dot += rows[i][p] * rows[j][p]
                result.append(dot / denominator)
        return result

    first = gram(0)
    if operation == 0:
        result = first
    else:
        second = gram(1)
        loss = 0.0
        for i in range(len(first)):
            difference = first[i] - second[i]
            loss += difference * difference
        result = [loss]
    return len(result) * 8, struct.pack("<" + "d" * len(result), *result)
