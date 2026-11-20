"""Independent bounded-language generation reference for CYK fixtures."""

INVALID_RESULT = -1
MAX_NONTERMINALS = 4
MAX_TERMINALS = 2
MAX_WORD_LENGTH = 8
MAX_PRODUCTIONS = 12
MAX_VALID_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62


def _parse_frame(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    variables, alphabet, size, rule_count, start = values[:5]
    if (not 1 <= variables <= MAX_NONTERMINALS
            or not 1 <= alphabet <= MAX_TERMINALS
            or not 1 <= size <= MAX_WORD_LENGTH
            or not 0 <= rule_count <= MAX_PRODUCTIONS
            or not 0 <= start < variables
            or len(values) != 5 + size + 4 * rule_count):
        return None
    word = tuple(values[5:5 + size])
    if any(token < 0 or token >= alphabet for token in word):
        return None
    rules = []
    base = 5 + size
    for rule_index in range(rule_count):
        mode, parent, first, second = values[base + 4 * rule_index:base + 4 * rule_index + 4]
        if not 0 <= parent < variables:
            return None
        if mode == 0:
            if not 0 <= first < alphabet or second != 0:
                return None
        elif mode == 1:
            if not 0 <= first < variables or not 0 <= second < variables:
                return None
        else:
            return None
        rules.append((mode, parent, first, second))
    return variables, alphabet, word, start, rules


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse_frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    variables, _alphabet, target, start, rules = parsed

    # Generate each nonterminal's finite language in increasing word length.
    # Positive-length CNF productions make every RHS language available before
    # its parent length is considered; no epsilon or unit rule can cycle here.
    languages = [[set() for _ in range(len(target) + 1)] for _ in range(variables)]
    for width in range(1, len(target) + 1):
        for mode, lhs, first, second in rules:
            if mode == 0 and width == 1:
                languages[lhs][1].add((first,))
        for mode, lhs, left_symbol, right_symbol in rules:
            if mode != 1:
                continue
            for left_width in range(1, width):
                right_width = width - left_width
                for left_word in languages[left_symbol][left_width]:
                    for right_word in languages[right_symbol][right_width]:
                        languages[lhs][width].add(left_word + right_word)

    return int(target in languages[start][len(target)])
