"""Levelwise wavelet-matrix reference for the bounded query contract."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)) or len(values) < 2:
        return -1
    n = values[0]
    if not 1 <= n <= 64 or len(values) < n + 2:
        return -1
    data = values[1:n + 1]
    q = values[n + 1]
    if any(x < -1000 or x > 1000 for x in data) or not 0 <= q <= 128 or len(values) != n + 2 + 5*q:
        return -1
    current = [x + 1000 for x in data]
    prefixes, zero_counts = [], []
    for bit in range(10, -1, -1):
        prefix = [0]
        zero, one = [], []
        for x in current:
            is_zero = (x >> bit) & 1 == 0
            prefix.append(prefix[-1] + is_zero)
            (zero if is_zero else one).append(x)
        prefixes.append(prefix)
        zero_counts.append(len(zero))
        current = zero + one

    def less(left, right, key):
        count = 0
        for level, bit in enumerate(range(10, -1, -1)):
            lzero, rzero = prefixes[level][left], prefixes[level][right]
            if (key >> bit) & 1:
                count += rzero - lzero
                left = zero_counts[level] + left - lzero
                right = zero_counts[level] + right - rzero
            else:
                left, right = lzero, rzero
        return count

    total = 0
    for j in range(q):
        op, a, b, c, d = values[n + 2 + 5*j:n + 7 + 5*j]
        if op == 0:
            if not -1000 <= a <= 1000 or not -1 <= b < n:
                return -1
            answer = less(0, b + 1, a + 1001) - less(0, b + 1, a + 1000)
        elif op == 1:
            if not 0 <= a <= b < n or not 0 <= c <= b - a:
                return -1
            left, right, kth, key = a, b + 1, c, 0
            for level, bit in enumerate(range(10, -1, -1)):
                lzero, rzero = prefixes[level][left], prefixes[level][right]
                count = rzero - lzero
                if kth < count:
                    left, right = lzero, rzero
                else:
                    kth -= count
                    key |= 1 << bit
                    left = zero_counts[level] + left - lzero
                    right = zero_counts[level] + right - rzero
            answer = key - 1000
        elif op == 2:
            if not 0 <= a <= b < n or not -1000 <= c <= d <= 1000:
                return -1
            answer = less(a, b + 1, d + 1001) - less(a, b + 1, c + 1000)
        else:
            return -1
        total += (j + 1) * (answer + 1_000_001)
    return total
