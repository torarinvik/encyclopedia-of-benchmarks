"""Independent period-first enumerator for the bounded approximate-square profile."""

MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 6160
MAX_OUTPUT_ELEMENTS = 770


def verify(values):
    if values is None or len(values) < 2 or len(values) > 34:
        return -1, b""
    n = values[0]
    k = values[1]
    if n < 2 or n > 32 or k < 0 or k > 8 or len(values) != n + 2:
        return -1, b""
    symbols = values[2:]
    if any(x not in (0, 1, 2, 3) for x in symbols):
        return -1, b""
    records = []
    for period in range(1, n // 2 + 1):
        for start in range(0, n - 2 * period + 1):
            errors = 0
            for offset in range(period):
                if symbols[start + offset] != symbols[start + period + offset]:
                    errors += 1
            if errors <= k:
                records.append((start, period, errors))
    records.sort(key=lambda r: (r[0], r[1]))
    flattened = [len(records)]
    for record in records:
        flattened.extend(record)
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in flattened)
    return len(raw), raw
