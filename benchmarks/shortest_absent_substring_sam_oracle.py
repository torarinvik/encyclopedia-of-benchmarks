"""Shortest missing word using a suffix automaton and state DAG DP."""

from collections.abc import Sequence


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
    transitions = [{}]
    links = [-1]
    lengths = [0]
    last = 0
    for symbol in values[2:]:
        current = len(links)
        transitions.append({}); lengths.append(lengths[last]+1); links.append(0)
        p = last
        while p >= 0 and symbol not in transitions[p]:
            transitions[p][symbol] = current
            p = links[p]
        if p >= 0:
            q = transitions[p][symbol]
            if lengths[p]+1 == lengths[q]:
                links[current] = q
            else:
                clone = len(links)
                transitions.append(transitions[q].copy()); lengths.append(lengths[p]+1); links.append(links[q])
                while p >= 0 and transitions[p].get(symbol) == q:
                    transitions[p][symbol] = clone
                    p = links[p]
                links[q] = links[current] = clone
        last = current
    dp = [0] * len(links)
    for state in sorted(range(len(links)), key=lambda s: lengths[s], reverse=True):
        dp[state] = 1 + min((dp[transitions[state][symbol]] if symbol in transitions[state] else 0)
                            for symbol in range(alphabet))
    answer = bytearray()
    state = 0
    while True:
        for symbol in range(alphabet):
            child = transitions[state].get(symbol)
            if child is None:
                if dp[state] == 1:
                    answer.append(symbol)
                    state = -1
                    break
            elif dp[state] == 1 + dp[child]:
                answer.append(symbol)
                state = child
                break
        if state < 0:
            break
    if output_is_null or capacity is not None and capacity < len(answer):
        return -2, b""
    return len(answer), bytes(answer)
