"""Clean-room CYK recognition oracle for a small Chomsky-normal grammar."""

INVALID_RESULT = -1
MAX_NONTERMINALS = 4
MAX_TERMINALS = 2
MAX_WORD_LENGTH = 8
MAX_PRODUCTIONS = 12
MAX_VALID_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_RESULT = 1


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    nonterminals, terminals, word_length, production_count, start = values[:5]
    if (not 1 <= nonterminals <= MAX_NONTERMINALS
            or not 1 <= terminals <= MAX_TERMINALS
            or not 1 <= word_length <= MAX_WORD_LENGTH
            or not 0 <= production_count <= MAX_PRODUCTIONS
            or not 0 <= start < nonterminals):
        return None
    if len(values) != 5 + word_length + 4 * production_count:
        return None

    word = tuple(values[5:5 + word_length])
    if any(not 0 <= token < terminals for token in word):
        return None

    productions = []
    offset = 5 + word_length
    for index in range(production_count):
        kind, lhs, first, second = values[offset + 4 * index:offset + 4 * index + 4]
        if not 0 <= lhs < nonterminals:
            return None
        if kind == 0:
            if not 0 <= first < terminals or second != 0:
                return None
        elif kind == 1:
            if not 0 <= first < nonterminals or not 0 <= second < nonterminals:
                return None
        else:
            return None
        # Repeated rows are permitted and have ordinary set-of-productions semantics.
        productions.append((kind, lhs, first, second))
    return nonterminals, word, start, productions


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    nonterminals, word, start_symbol, productions = parsed
    length = len(word)

    # chart[A][i][width] says that A derives the half-open word interval
    # [i, i+width).  Widths are filled from short to long.
    chart = [[[False] * (length + 1) for _ in range(length)]
             for _ in range(nonterminals)]
    for position, token in enumerate(word):
        for kind, lhs, first, _second in productions:
            if kind == 0 and first == token:
                chart[lhs][position][1] = True

    for width in range(2, length + 1):
        for left in range(length - width + 1):
            for kind, lhs, first, second in productions:
                if kind != 1:
                    continue
                for split in range(1, width):
                    if (chart[first][left][split]
                            and chart[second][left + split][width - split]):
                        chart[lhs][left][width] = True
                        break

    return int(chart[start_symbol][0][length])
