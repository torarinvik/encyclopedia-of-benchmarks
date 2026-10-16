"""Runtime oracle for bounded 0/1 selection under zero/one budgets."""

MAX_INPUT_LENGTH = 67


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    count, zero_budget, one_budget = values[:3]
    if not 0 <= count <= 32 or not 0 <= zero_budget <= 32 or not 0 <= one_budget <= 32:
        return -1
    if len(values) != 3 + 2 * count:
        return -1
    dp = [[0] * (one_budget + 1) for _ in range(zero_budget + 1)]
    for zeros, ones in zip(values[3::2], values[4::2]):
        if not 0 <= zeros <= 32 or not 0 <= ones <= 32:
            return -1
        for z in range(zero_budget, zeros - 1, -1):
            for o in range(one_budget, ones - 1, -1):
                dp[z][o] = max(dp[z][o], dp[z - zeros][o - ones] + 1)
    return dp[zero_budget][one_budget]
