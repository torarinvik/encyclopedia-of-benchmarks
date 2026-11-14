"""Monotone-chain reference with the divide-and-conquer profile's x restriction."""

from c.chan_output_sensitive_hull.independent_oracle import expected_output as general_hull


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    result, payload = general_hull(values, input_is_null=input_is_null, input_length=input_length)
    if result < 0:
        return -1, b""
    if len(set(values[1::2])) != values[0]:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return result, payload
