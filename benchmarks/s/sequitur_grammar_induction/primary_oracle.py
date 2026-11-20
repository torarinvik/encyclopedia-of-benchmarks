"""Bounded deterministic Sequitur-style grammar induction reference."""

MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 64
ALPHABET_MAX = 255
MAX_VALID_INPUT_LENGTH = 1 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 64_064

_MAX_RULE_IDS = 256
_NONTERMINAL_BASE = 256


def parse(values):
    if values is None or not hasattr(values, "__len__"):
        return None
    if len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = values[0]
    if isinstance(n, bool) or not isinstance(n, int) or not MIN_TEXT_LENGTH <= n <= MAX_TEXT_LENGTH:
        return None
    if len(values) != 1 + n:
        return None
    text = values[1:]
    if any(isinstance(x, bool) or not isinstance(x, int) or not 0 <= x <= ALPHABET_MAX for x in text):
        return None
    return text


def _replace_pair(rules, lengths, rule, position, replacement):
    length = lengths[rule]
    for index in range(position + 2, length):
        rules[rule][index - 1] = rules[rule][index]
    lengths[rule] -= 1
    rules[rule][position] = replacement


def _find_duplicate(rules, lengths, active, next_rule):
    for first_rule in range(next_rule):
        if not active[first_rule]:
            continue
        for first_pos in range(lengths[first_rule] - 1):
            left = rules[first_rule][first_pos]
            right = rules[first_rule][first_pos + 1]
            for second_rule in range(first_rule, next_rule):
                if not active[second_rule]:
                    continue
                second_start = first_pos + 2 if second_rule == first_rule else 0
                for second_pos in range(second_start, lengths[second_rule] - 1):
                    if (rules[second_rule][second_pos] == left and
                            rules[second_rule][second_pos + 1] == right):
                        return (first_rule, first_pos, second_rule, second_pos, left, right)
    return None


def _cleanup_one(rules, lengths, active, next_rule):
    for target in range(1, next_rule):
        if not active[target]:
            continue
        references = []
        for rule in range(next_rule):
            if active[rule]:
                for position in range(lengths[rule]):
                    if rules[rule][position] == _NONTERMINAL_BASE + target:
                        references.append((rule, position))
        if len(references) == 0:
            active[target] = False
            lengths[target] = 0
            return True
        if len(references) == 1:
            parent, position = references[0]
            replacement = rules[target][:lengths[target]]
            old_length = lengths[parent]
            delta = len(replacement) - 1
            for index in range(old_length - 1, position, -1):
                rules[parent][index + delta] = rules[parent][index]
            for offset, symbol in enumerate(replacement):
                rules[parent][position + offset] = symbol
            lengths[parent] += delta
            active[target] = False
            lengths[target] = 0
            return True
    return False


def build(text):
    """Return `(rule_count, rhs_symbol_count)` for the specified repair order."""
    rules = [[0] * MAX_TEXT_LENGTH for _ in range(_MAX_RULE_IDS)]
    lengths = [0] * _MAX_RULE_IDS
    active = [False] * _MAX_RULE_IDS
    active[0] = True
    next_rule = 1

    for symbol in text:
        rules[0][lengths[0]] = symbol
        lengths[0] += 1
        while True:
            while _cleanup_one(rules, lengths, active, next_rule):
                pass
            duplicate = _find_duplicate(rules, lengths, active, next_rule)
            if duplicate is None:
                break
            first_rule, first_pos, second_rule, second_pos, left, right = duplicate

            existing_rule = None
            for rule in range(1, next_rule):
                if active[rule] and lengths[rule] == 2 and rules[rule][0] == left and rules[rule][1] == right:
                    existing_rule = rule
                    break

            if existing_rule is not None:
                preserved = (existing_rule, 0)
                target = (first_rule, first_pos)
                if target == preserved:
                    target = (second_rule, second_pos)
                _replace_pair(rules, lengths, target[0], target[1], _NONTERMINAL_BASE + existing_rule)
            else:
                if next_rule >= _MAX_RULE_IDS:
                    raise ValueError("bounded rule-id capacity exceeded")
                fresh = next_rule
                next_rule += 1
                active[fresh] = True
                lengths[fresh] = 2
                rules[fresh][0] = left
                rules[fresh][1] = right
                replacement = _NONTERMINAL_BASE + fresh
                locations = [(first_rule, first_pos), (second_rule, second_pos)]
                locations.sort(reverse=True)
                for rule, position in locations:
                    _replace_pair(rules, lengths, rule, position, replacement)

    rule_count = sum(active[rule] for rule in range(1, next_rule))
    rhs_symbol_count = sum(lengths[rule] for rule in range(next_rule) if active[rule])
    return rule_count, rhs_symbol_count


def expected_result(values, input_is_null=False, input_length=None):
    if not isinstance(input_is_null, bool):
        return -1
    if input_length is not None and (isinstance(input_length, bool) or not isinstance(input_length, int)):
        return -1
    if input_is_null:
        return -1
    if values is None:
        return -1
    try:
        actual_length = len(values)
    except (TypeError, ValueError, OverflowError):
        return -1
    length = actual_length if input_length is None else input_length
    if length < 0 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if length != actual_length:
        return -1
    text = parse(values)
    if text is None:
        return -1
    rules, symbols = build(text)
    result = 1000 * rules + symbols
    return result if result <= MAX_RESULT else -1


def expected(values):
    return expected_result(values)
