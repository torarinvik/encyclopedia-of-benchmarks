"""Array-based exact reference for bounded Tunstall codebook construction."""

MIN_ALPHABET_SIZE = 2
MAX_ALPHABET_SIZE = 4
MIN_CODE_BITS = 2
MAX_CODE_BITS = 4
MAX_WEIGHT_SUM = 8
MAX_VALID_INPUT_LENGTH = MAX_ALPHABET_SIZE + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_LEAVES = 16
MAX_DEPTH = 15
MAX_S = 15 * (8**16)
RESULT_FACTOR = MAX_S + 1
MAX_RESULT = MAX_LEAVES * RESULT_FACTOR + MAX_S


def parse(values):
    if values is None:
        return None
    try:
        size = len(values)
        if size < MIN_ALPHABET_SIZE + 2 or size > MAX_PARSEABLE_INPUT_LENGTH:
            return None
        alphabet_size = values[0]
        code_bits = values[1]
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if isinstance(alphabet_size, bool) or not isinstance(alphabet_size, int):
        return None
    if isinstance(code_bits, bool) or not isinstance(code_bits, int):
        return None
    if not MIN_ALPHABET_SIZE <= alphabet_size <= MAX_ALPHABET_SIZE:
        return None
    if not MIN_CODE_BITS <= code_bits <= MAX_CODE_BITS:
        return None
    if size != alphabet_size + 2:
        return None
    try:
        weights = list(values[2:])
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if len(weights) != alphabet_size:
        return None
    if any(isinstance(weight, bool) or not isinstance(weight, int) or weight <= 0 for weight in weights):
        return None
    if sum(weights) > MAX_WEIGHT_SUM:
        return None
    return alphabet_size, code_bits, weights


def target_leaf_count(alphabet_size, code_bits):
    cap = 1 << code_bits
    return cap - ((cap - 1) % (alphabet_size - 1))


def _lex_less(nodes, left_index, right_index):
    return nodes[left_index]["phrase"] < nodes[right_index]["phrase"]


def construct(alphabet_size, code_bits, weights):
    total = sum(weights)
    powers = [1] * 17
    for exponent in range(1, len(powers)):
        powers[exponent] = powers[exponent - 1] * total

    target = target_leaf_count(alphabet_size, code_bits)
    nodes = [{"phrase": (), "depth": 0, "product": 1, "leaf": False}]
    leaves = []
    for symbol, weight in enumerate(weights):
        leaves.append(len(nodes))
        nodes.append({"phrase": (symbol,), "depth": 1, "product": weight, "leaf": True})

    scaled_expectation = powers[16]  # The root is internal and has probability one.
    while len(leaves) < target:
        best_position = 0
        best_node = leaves[0]
        best = nodes[best_node]
        best_key = best["product"] * powers[MAX_DEPTH - best["depth"]]
        for position in range(1, len(leaves)):
            candidate_index = leaves[position]
            candidate = nodes[candidate_index]
            key = candidate["product"] * powers[MAX_DEPTH - candidate["depth"]]
            if key > best_key or (key == best_key and _lex_less(nodes, candidate_index, best_node)):
                best_position = position
                best_node = candidate_index
                best = candidate
                best_key = key

        best["leaf"] = False
        scaled_expectation += best["product"] * powers[16 - best["depth"]]
        leaves.pop(best_position)
        for symbol, weight in enumerate(weights):
            child_index = len(nodes)
            nodes.append({
                "phrase": best["phrase"] + (symbol,),
                "depth": best["depth"] + 1,
                "product": best["product"] * weight,
                "leaf": True,
            })
            leaves.append(child_index)

    result = target * RESULT_FACTOR + scaled_expectation
    return result if scaled_expectation <= MAX_S and result <= MAX_RESULT else -1


def expected_result(values, input_is_null=False, input_length=None):
    if not isinstance(input_is_null, bool):
        return -1
    if input_length is not None and (isinstance(input_length, bool) or not isinstance(input_length, int)):
        return -1
    if input_is_null or values is None:
        return -1
    try:
        actual_length = len(values)
    except (TypeError, ValueError, OverflowError):
        return -1
    length = actual_length if input_length is None else input_length
    if length < 0 or length > MAX_PARSEABLE_INPUT_LENGTH or length != actual_length:
        return -1
    parsed = parse(values)
    if parsed is None:
        return -1
    return construct(*parsed)


def expected(values):
    return expected_result(values)
