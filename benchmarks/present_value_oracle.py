"""Independent oracle for the bounded Python/C# present-value contract."""

INVALID_RESULT = -1e300
MAX_FLOW_COUNT = 8
MAX_INPUT_LENGTH = MAX_FLOW_COUNT + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_FLOW_COUNT + 3


def expected_result(values: list[int]) -> float:
    if not isinstance(values, list) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    count, rate_ppm, *flows_milli = values
    if not 1 <= count <= MAX_FLOW_COUNT or len(flows_milli) != count:
        return INVALID_RESULT
    if rate_ppm not in (0, 1_000_000):
        return INVALID_RESULT
    if any(not -1_000_000 <= flow <= 1_000_000 or flow % 125 != 0 for flow in flows_milli):
        return INVALID_RESULT
    rate = rate_ppm / 1_000_000
    present_value = 0.0
    for index, flow_milli in enumerate(flows_milli):
        cash_flow = flow_milli / 1_000
        present_value += cash_flow / ((1.0 + rate) ** index)
    return round(present_value, 2)
