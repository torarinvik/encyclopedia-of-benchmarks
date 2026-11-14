"""Unexecuted direct pair enumeration for bounded closest-pair distance."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 5 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1
    n = values[0]
    if not 2 <= n <= 64 or len(values) != 1+2*n or any(x < -1000 or x > 1000 for x in values[1:]):
        return -1
    points = list(zip(values[1::2], values[2::2]))
    return min((points[i][0]-points[j][0])**2 + (points[i][1]-points[j][1])**2
               for i in range(n) for j in range(i+1,n))
