"""Reference longest-repeating-subsequence contract."""
MAX_INPUT_LENGTH = 256
MAX_SEQUENCE_LENGTH = 255

def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return -1
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_SEQUENCE_LENGTH or len(values) != n + 1:
        return -1
    seq = values[1:]
    if any(type(ch) is not int or not 0 <= ch <= 127 for ch in seq):
        return -1
    dp = [[0] * (n + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, n + 1):
            if seq[i - 1] == seq[j - 1] and i != j:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
    return dp[n][n]
