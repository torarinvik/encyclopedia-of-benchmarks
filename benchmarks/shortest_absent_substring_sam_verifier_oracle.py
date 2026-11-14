"""Reference enumerating candidate words by length and lexical order."""

from collections.abc import Sequence
from itertools import product


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 66)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 2 <= len(values) <= 66 or any(type(x) is not int for x in values):
        return -1, b""
    alphabet, n = values[:2]
    if not 2 <= alphabet <= 4 or not 0 <= n <= 64 or len(values) != 2+n or any(not 0 <= x < alphabet for x in values[2:]):
        return -1, b""
    text = tuple(values[2:])
    for size in range(1, 7):
        present = {text[i:i+size] for i in range(n-size+1)}
        for word in product(range(alphabet), repeat=size):
            if word not in present:
                payload = bytes(word)
                if output_is_null or capacity is not None and capacity < size:
                    return -2, b""
                return size, payload
    raise AssertionError("bounded alphabet must have a missing word by length six")
