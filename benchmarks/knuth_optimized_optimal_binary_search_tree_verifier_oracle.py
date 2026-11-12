"""Independent cubic root-enumeration verifier for optimal BST cost."""

MAX_N = 64
MAX_FREQUENCY = 1_000_000
MAX_INPUT_LENGTH = 65


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != n + 1:
        return -1
    f = values[1:]
    if any(not 0 <= value <= MAX_FREQUENCY for value in f):
        return -1
    prefix = [0]
    for value in f:
        prefix.append(prefix[-1] + value)
    dp = [[0] * n for _ in range(n)]
    for i, value in enumerate(f):
        dp[i][i] = value
    for width in range(2, n + 1):
        for left in range(n - width + 1):
            right = left + width - 1
            total = prefix[right + 1] - prefix[left]
            best = None
            for root in range(left, right + 1):
                value = total
                if root > left:
                    value += dp[left][root - 1]
                if root < right:
                    value += dp[root + 1][right]
                if best is None or value < best:
                    best = value
            dp[left][right] = best
    return dp[0][n - 1]
