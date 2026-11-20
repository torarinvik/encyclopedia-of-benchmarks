"""Independent occurrence-table reference for the bounded grammar profile."""

from .primary_oracle import (
    ALPHABET_MAX,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_TEXT_LENGTH,
)

_BASE = 256
_RULE_CAPACITY = 256


def _parse(values):
    if values is None or not hasattr(values, "__len__"):
        return None
    if len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    count = values[0]
    if isinstance(count, bool) or not isinstance(count, int) or not 0 <= count <= MAX_TEXT_LENGTH:
        return None
    if len(values) != count + 1:
        return None
    result = list(values[1:])
    if any(isinstance(symbol, bool) or not isinstance(symbol, int) or not 0 <= symbol <= ALPHABET_MAX
           for symbol in result):
        return None
    return result


def _locations(rules, live, next_id):
    table = {}
    for rule_id in range(next_id):
        if not live[rule_id]:
            continue
        row = rules[rule_id]
        for offset in range(len(row) - 1):
            pair = (row[offset], row[offset + 1])
            table.setdefault(pair, []).append((rule_id, offset))
    return table


def _first_repair(table):
    candidates = []
    for pair, occurrences in table.items():
        ordered = sorted(occurrences)
        for left_index, first in enumerate(ordered):
            for second in ordered[left_index + 1:]:
                if first[0] == second[0] and second[1] < first[1] + 2:
                    continue
                candidates.append((first, second, pair))
                break
    if not candidates:
        return None
    return min(candidates, key=lambda item: (item[0], item[1]))


def _replace(row, offset, token):
    row[offset:offset + 2] = [token]


def _remove_one_use(rules, live, next_id):
    for target in range(1, next_id):
        if not live[target]:
            continue
        locations = []
        token = _BASE + target
        for rule_id in range(next_id):
            if live[rule_id]:
                locations.extend((rule_id, offset) for offset, value in enumerate(rules[rule_id]) if value == token)
        if not locations:
            live[target] = False
            rules[target] = []
            return True
        if len(locations) == 1:
            parent, offset = locations[0]
            rules[parent][offset:offset + 1] = rules[target]
            live[target] = False
            rules[target] = []
            return True
    return False


def _counts(symbols):
    rules = [[] for _ in range(_RULE_CAPACITY)]
    live = [False] * _RULE_CAPACITY
    live[0] = True
    next_id = 1
    for symbol in symbols:
        rules[0].append(symbol)
        while True:
            while _remove_one_use(rules, live, next_id):
                pass
            table = _locations(rules, live, next_id)
            repair = _first_repair(table)
            if repair is None:
                break
            first, second, pair = repair
            left, right = pair
            exact = next((rule_id for rule_id in range(1, next_id)
                          if live[rule_id] and rules[rule_id] == [left, right]), None)
            if exact is not None:
                target = first if first != (exact, 0) else second
                _replace(rules[target[0]], target[1], _BASE + exact)
            else:
                if next_id >= _RULE_CAPACITY:
                    raise ValueError("bounded rule-id capacity exceeded")
                fresh = next_id
                next_id += 1
                live[fresh] = True
                rules[fresh] = [left, right]
                for rule_id, offset in sorted((first, second), reverse=True):
                    _replace(rules[rule_id], offset, _BASE + fresh)
    count = sum(live[1:next_id])
    size = sum(len(rules[rule_id]) for rule_id in range(next_id) if live[rule_id])
    return count, size


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
    symbols = _parse(values)
    if symbols is None:
        return -1
    count, size = _counts(symbols)
    result = 1000 * count + size
    return result if result <= MAX_RESULT else -1


def expected(values):
    return expected_result(values)
