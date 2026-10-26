"""Independent candidate scan for cardinality-constrained first fit."""
MAX_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 264


def verify(values):
    if values is None or len(values) < 4 or len(values) > 35:
        return -1, b""
    n, limit, cap = values[0], values[1], values[2]
    if n < 1 or n > 32 or limit < 1 or limit > 32 or cap < 1 or cap > 10000 or len(values) != n + 3:
        return -1, b""
    sizes = values[3:]
    if any(x < 1 or x > cap for x in sizes):
        return -1, b""
    bins = []
    owners = []
    for weight in sizes:
        for index, contents in enumerate(bins):
            if len(contents) < limit and sum(contents) <= cap - weight:
                contents.append(weight)
                owners.append(index)
                break
        else:
            bins.append([weight])
            index = len(bins) - 1
            owners.append(index)
    flat = [len(bins), *owners]
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in flat)
    return len(raw), raw
