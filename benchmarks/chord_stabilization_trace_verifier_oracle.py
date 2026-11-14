"""Independent interval-comparison reference for Chord stabilization."""

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 115)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 6 <= len(values) <= 115 or any(type(x) is not int for x in values):
        return -1, b""
    bits, n, q = values[:3]
    if not 1 <= bits <= 6 or not 1 <= n <= min(16, 1 << bits) or not 0 <= q <= 64 or len(values) != 3+3*n+q:
        return -1, b""
    ids = values[3:3+n]
    succ = list(values[3+n:3+2*n])
    pred = list(values[3+2*n:3+3*n])
    schedule = values[3+3*n:]
    if (any(not 0 <= x < 1 << bits for x in ids)
            or any(ids[i] >= ids[i+1] for i in range(n-1))
            or any(not 0 <= x < n for x in succ)
            or any(not -1 <= x < n for x in pred)
            or any(not 0 <= x < n for x in schedule)):
        return -1, b""
    def between(left: int, item: int, right: int) -> bool:
        a, x, b = ids[left], ids[item], ids[right]
        if a < b:
            return a < x < b
        if a > b:
            return x > a or x < b
        return x != a
    for node in schedule:
        old_successor = succ[node]
        candidate = pred[old_successor]
        if candidate != -1 and between(node, candidate, old_successor):
            succ[node] = candidate
        receiver = succ[node]
        old_predecessor = pred[receiver]
        if old_predecessor == -1 or between(old_predecessor, node, receiver):
            pred[receiver] = node
    payload = bytes(succ + [255 if x == -1 else x for x in pred])
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
