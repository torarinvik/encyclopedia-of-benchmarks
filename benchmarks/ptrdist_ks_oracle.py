"""Independent oracle for the bounded Ptrdist Kernighan-Lin profile.

The implementation chooses swaps from freshly recomputed cut deltas; this
oracle instead evaluates every candidate by constructing its trial partition
and counting hyperedge crossings directly.
"""

from __future__ import annotations

MAX_MODULES = 8
MAX_NETS = 16
MAX_INPUT_LENGTH = 2 + MAX_NETS * (1 + MAX_MODULES)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _metrics(side: list[int], nets: list[list[int]]) -> tuple[int, int]:
    edge_cuts = 0
    net_cuts = 0
    for members in nets:
        low = sum(side[module] == 0 for module in members)
        high = len(members) - low
        edge_cuts += low * high
        if low and high:
            net_cuts += 1
    return edge_cuts, net_cuts


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    module_count, net_count = values[0], values[1]
    if not 2 <= module_count <= MAX_MODULES or module_count % 2:
        return INVALID_RESULT
    if not 0 <= net_count <= MAX_NETS:
        return INVALID_RESULT

    cursor = 2
    nets: list[list[int]] = []
    for _ in range(net_count):
        if cursor >= len(values):
            return INVALID_RESULT
        degree = values[cursor]
        cursor += 1
        if not 2 <= degree <= module_count or cursor + degree > len(values):
            return INVALID_RESULT
        members = list(values[cursor : cursor + degree])
        cursor += degree
        if any(member < 0 or member >= module_count for member in members):
            return INVALID_RESULT
        if len(set(members)) != degree:
            return INVALID_RESULT
        nets.append(members)
    if cursor != len(values):
        return INVALID_RESULT

    half = module_count // 2
    order_a = list(range(half))
    order_b = list(range(half, module_count))
    side = [0] * half + [1] * half
    accepted_passes = 0

    while True:
        work = side.copy()
        remaining_a = order_a.copy()
        remaining_b = order_b.copy()
        selected_a: list[int] = []
        selected_b: list[int] = []
        cumulative_gain = 0
        best_gain: int | None = None
        best_prefix = 0

        for step in range(half):
            baseline, _ = _metrics(work, nets)
            chosen: tuple[int, int] | None = None
            pair_gain: int | None = None
            for a in remaining_a:
                for b in remaining_b:
                    trial = work.copy()
                    trial[a], trial[b] = trial[b], trial[a]
                    trial_cuts, _ = _metrics(trial, nets)
                    gain = baseline - trial_cuts
                    if pair_gain is None or gain > pair_gain:
                        pair_gain = gain
                        chosen = (a, b)
            assert chosen is not None and pair_gain is not None
            a, b = chosen
            selected_a.append(a)
            selected_b.append(b)
            work[a], work[b] = work[b], work[a]
            remaining_a.remove(a)
            remaining_b.remove(b)
            cumulative_gain += pair_gain
            if best_gain is None or cumulative_gain > best_gain:
                best_gain = cumulative_gain
                best_prefix = step + 1

        if best_gain is None or best_gain <= 0:
            break
        order_a = selected_b[:best_prefix] + selected_a[best_prefix:]
        order_b = selected_a[:best_prefix] + selected_b[best_prefix:]
        side = [1] * module_count
        for module in order_a:
            side[module] = 0
        accepted_passes += 1

    edge_cuts, net_cuts = _metrics(side, nets)
    partition_mask = sum(1 << module for module, group in enumerate(side) if group == 0)
    return partition_mask + (edge_cuts << 8) + (net_cuts << 17) + (accepted_passes << 22)


def generated_inputs() -> list[list[int]]:
    """A small deterministic corpus for verifier expansion."""
    return [
        [2, 0],
        [2, 1, 2, 0, 1],
        [4, 2, 2, 0, 2, 2, 1, 3],
        [4, 3, 2, 0, 2, 2, 1, 3, 4, 0, 1, 2, 3],
        [6, 4, 3, 0, 2, 4, 3, 1, 3, 5, 2, 0, 1, 2, 4, 5],
    ]
