"""Primary rooted-component recurrence for connected labeled graph counts."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 512
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return -1
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N:
        return -1

    factorial = [1] * (n + 1)
    for i in range(1, n + 1):
        factorial[i] = factorial[i - 1] * i % MODULUS
    inverse_factorial = [1] * (n + 1)
    inverse_factorial[n] = pow(factorial[n], MODULUS - 2, MODULUS)
    for i in range(n, 0, -1):
        inverse_factorial[i - 1] = inverse_factorial[i] * i % MODULUS

    all_graphs = [1] * (n + 1)
    pair_choices = 1
    for size in range(1, n + 1):
        all_graphs[size] = all_graphs[size - 1] * pair_choices % MODULUS
        pair_choices = pair_choices * 2 % MODULUS

    connected = [0] * (n + 1)
    connected[1] = 1
    for size in range(2, n + 1):
        disconnected_rooted = 0
        for component_size in range(1, size):
            choose = factorial[size - 1]
            choose = choose * inverse_factorial[component_size - 1] % MODULUS
            choose = choose * inverse_factorial[size - component_size] % MODULUS
            term = choose * connected[component_size] % MODULUS
            term = term * all_graphs[size - component_size] % MODULUS
            disconnected_rooted = (disconnected_rooted + term) % MODULUS
        connected[size] = (all_graphs[size] - disconnected_rooted) % MODULUS
    return connected[n]
