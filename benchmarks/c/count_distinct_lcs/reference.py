"""Unexecuted distinct-LCS counting models."""

MODULUS = 1_000_000_007


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 131
            or any(type(value) is not int for value in values)):
        return None
    n, m = values[:2]
    if not 0 <= n <= 64 or not 0 <= m <= 64 or len(values) != 2+n+m:
        return None
    if any(not 0 <= symbol <= 255 for symbol in values[2:]):
        return None
    return values[2:2+n], values[2+n:]


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    lengths = [0]*(len(b)+1)
    counts = [1]*(len(b)+1)
    for left in a:
        next_lengths = [0]*(len(b)+1)
        next_counts = [1]*(len(b)+1)
        for j, right in enumerate(b, 1):
            if left == right:
                next_lengths[j] = lengths[j-1]+1
                next_counts[j] = counts[j-1]
            else:
                best = max(lengths[j], next_lengths[j-1])
                count = (counts[j] if lengths[j] == best else 0)
                count += next_counts[j-1] if next_lengths[j-1] == best else 0
                if lengths[j-1] == best:
                    count -= counts[j-1]
                next_lengths[j] = best
                next_counts[j] = count % MODULUS
        lengths, counts = next_lengths, next_counts
    return counts[-1]


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    if len(a) > 16 or len(b) > 16:
        raise ValueError("exhaustive reference is limited to 16 symbols per sequence")
    def subsequences(sequence):
        return {tuple(sequence[i] for i in range(len(sequence)) if mask & (1 << i))
                for mask in range(1 << len(sequence))}
    common = subsequences(a) & subsequences(b)
    longest = max(map(len, common))
    return sum(len(value) == longest for value in common) % MODULUS
