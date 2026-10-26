"""Independent First Fit checker with explicit first-eligible search."""

CAP = 1_000_000


def verify(values):
    if values is None or len(values) < 1:
        return -1, b""
    count = values[0]
    if count < 0 or count > 64 or len(values) != count + 1:
        return -1, b""
    if any(x <= 0 or x > CAP for x in values[1:]):
        return -1, b""
    bins = []
    ids = []
    for item in values[1:]:
        chosen = -1
        for idx in range(len(bins)):
            if bins[idx] <= CAP - item:
                chosen = idx
                break
        if chosen < 0:
            chosen = len(bins)
            bins.append(item)
        else:
            bins[chosen] += item
        ids.append(chosen)
    encoded = [len(bins)] + ids
    data = b"".join(x.to_bytes(8, "little", signed=True) for x in encoded)
    return len(data), data
