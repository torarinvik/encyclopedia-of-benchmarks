"""Runtime oracle for minimum weighted search cost of an ordered BST."""

MAX_INPUT_LENGTH = 33


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    count = values[0]
    if not 1 <= count <= 32 or len(values) != count + 1:
        return -1
    freq = values[1:]
    if any(not 0 <= x <= 1000 for x in freq):
        return -1
    dp = [[0] * count for _ in range(count)]
    prefix = [0]
    for value in freq:
        prefix.append(prefix[-1] + value)
    for i, value in enumerate(freq):
        dp[i][i] = value
    for width in range(2, count + 1):
        for start in range(count - width + 1):
            end = start + width - 1
            total = prefix[end + 1] - prefix[start]
            dp[start][end] = min(
                total + (dp[start][root - 1] if root > start else 0)
                + (dp[root + 1][end] if root < end else 0)
                for root in range(start, end + 1)
            )
    return dp[0][count - 1]
