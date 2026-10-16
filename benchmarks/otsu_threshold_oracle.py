"""Runtime oracle for bounded grayscale Otsu thresholding."""

MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 32


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 32 or len(values) != n + 1:
        return -1, b""
    pixels = values[1:]
    if any(not 0 <= x <= 255 for x in pixels):
        return -1, b""
    hist = [0] * 256
    for p in pixels:
        hist[p] += 1
    total = sum(i * hist[i] for i in range(256))
    wb = sf = 0
    current_max = 0.0
    threshold = 0
    for i in range(256):
        wb += hist[i]
        if wb == 0:
            continue
        wf = n - wb
        if wf == 0:
            break
        sf += i * hist[i]
        mb = sf / wb
        mf = (total - sf) / wf
        variance = wb * wf * (mb - mf) ** 2
        if variance > current_max:
            current_max = variance
            threshold = i
    result = bytes(255 if pixel > threshold else 0 for pixel in pixels)
    return len(result), result
