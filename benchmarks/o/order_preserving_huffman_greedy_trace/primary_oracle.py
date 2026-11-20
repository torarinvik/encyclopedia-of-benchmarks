"""Tree-node reference for the bounded greedy order-preserving merge trace."""

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MIN_SYMBOLS = 2
MAX_SYMBOLS = 8
MIN_WEIGHT = 1
MAX_WEIGHT = 15
MAX_TOTAL_WEIGHT = 120
MAX_DEPTH = 7
MAX_COST = 840
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 2048


def _encode(words):
    return b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX))
            or (capacity is not None and (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX))):
        return -1, b""
    if input_is_null:
        empty = values is None or (isinstance(values, (list, tuple)) and len(values) == 0)
        if not empty or input_length not in (None, 0):
            return -1, b""
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or not MIN_SYMBOLS + 1 <= len(values) <= MAX_VALID_INPUT_LENGTH):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    weights = values[1:]
    if type(n) is not int or not MIN_SYMBOLS <= n <= MAX_SYMBOLS or len(weights) != n:
        return -1, b""
    if any(type(weight) is not int or not MIN_WEIGHT <= weight <= MAX_WEIGHT for weight in weights):
        return -1, b""
    if sum(weights) > MAX_TOTAL_WEIGHT:
        return -1, b""

    node_weight = list(weights)
    left = [-1] * (2 * n - 1)
    right = [-1] * (2 * n - 1)
    active = list(range(n))
    next_node = n
    while len(active) > 1:
        chosen = 0
        best = node_weight[active[0]] + node_weight[active[1]]
        for i in range(1, len(active) - 1):
            pair_weight = node_weight[active[i]] + node_weight[active[i + 1]]
            if pair_weight < best:
                chosen, best = i, pair_weight
        a, b = active[chosen], active[chosen + 1]
        node_weight.append(best)
        left[next_node], right[next_node] = a, b
        active[chosen:chosen + 2] = [next_node]
        next_node += 1

    depths = [0] * n
    stack = [(active[0], 0)]
    while stack:
        node, depth = stack.pop()
        if node < n:
            depths[node] = depth
        else:
            stack.append((right[node], depth + 1))
            stack.append((left[node], depth + 1))
    cost = sum(weight * depth for weight, depth in zip(weights, depths))
    output = _encode([n, cost, *depths])
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
