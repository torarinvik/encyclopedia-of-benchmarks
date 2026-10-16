"""Independent bounded oracles for the four pinned Rust financial ratios."""

INVALID_RESULT = -1e300
MAX_ABS_VALUE = 1_000_000


def expected_result(values: list[int], algorithm: str) -> float:
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    if algorithm == "return_on_investment":
        if (len(values) != 2 or not -MAX_ABS_VALUE <= values[0] <= MAX_ABS_VALUE
                or not 1 <= values[1] <= MAX_ABS_VALUE):
            return INVALID_RESULT
        gain, cost = values
        return (float(gain) - float(cost)) / float(cost)
    if algorithm == "debt_to_equity":
        if (len(values) != 2 or not 0 <= values[0] <= MAX_ABS_VALUE
                or not 1 <= values[1] <= MAX_ABS_VALUE):
            return INVALID_RESULT
        debt, equity = values
        return float(debt) / float(equity)
    if algorithm == "gross_profit_margin":
        if (len(values) != 2 or not 1 <= values[0] <= MAX_ABS_VALUE
                or not 0 <= values[1] <= MAX_ABS_VALUE):
            return INVALID_RESULT
        revenue, cost = values
        return (float(revenue) - float(cost)) / float(revenue)
    if algorithm == "earnings_per_sale":
        if (len(values) != 3 or not -MAX_ABS_VALUE <= values[0] <= MAX_ABS_VALUE
                or not 0 <= values[1] <= MAX_ABS_VALUE
                or not 1 <= values[2] <= MAX_ABS_VALUE):
            return INVALID_RESULT
        net_income, preferred_dividend, average_shares = values
        return (float(net_income) - float(preferred_dividend)) / float(average_shares)
    raise ValueError(f"unknown finance ratio: {algorithm}")
