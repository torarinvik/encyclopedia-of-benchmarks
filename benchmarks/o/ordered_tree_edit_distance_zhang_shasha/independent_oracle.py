"""Small exhaustive tree-edit mapping reference, independent of forest DP."""

from __future__ import annotations

try:
    from .primary_oracle import parse_input
except ImportError:  # Support direct-file loading by package inventory tools.
    from primary_oracle import parse_input

MAX_INDEPENDENT_NODES = 8


def expected_result(values: list[int]) -> int:
    parsed = parse_input(values)
    if parsed is None:
        return -1
    labels_a, children_a, labels_b, children_b = parsed
    n, m = len(labels_a), len(labels_b)
    if n > MAX_INDEPENDENT_NODES or m > MAX_INDEPENDENT_NODES:
        raise ValueError("tree exceeds the bounded exhaustive mapping reference")

    def relations(children: list[list[int]]) -> tuple[list[list[bool]], list[int]]:
        count = len(children)
        ancestor = [[False] * count for _ in range(count)]
        preorder = [0] * count
        tick = 0

        def visit(v: int) -> None:
            nonlocal tick
            preorder[v] = tick
            tick += 1
            for child in children[v]:
                ancestor[v][child] = True
                visit(child)
                for desc in range(count):
                    if ancestor[child][desc]:
                        ancestor[v][desc] = True

        visit(0)
        return ancestor, preorder

    anc_a, pre_a = relations(children_a)
    anc_b, pre_b = relations(children_b)
    mapping = [-1] * n
    used = [False] * m
    best = n + m

    def relaxed_lower_bound(index: int) -> int:
        remaining_source = n - index
        remaining_target = sum(not present for present in used)
        source_counts = [0, 0, 0, 0]
        target_counts = [0, 0, 0, 0]
        for source in range(index, n):
            source_counts[labels_a[source]] += 1
        for target in range(m):
            if not used[target]:
                target_counts[labels_b[target]] += 1
        equal_pairs = sum(min(source_counts[label], target_counts[label]) for label in range(4))
        paired = min(remaining_source, remaining_target)
        return abs(remaining_source - remaining_target) + paired - equal_pairs

    def compatible(index: int, target: int) -> bool:
        for prior in range(index):
            mapped = mapping[prior]
            if mapped < 0:
                continue
            a_before = anc_a[prior][index]
            a_after = anc_a[index][prior]
            b_before = anc_b[mapped][target]
            b_after = anc_b[target][mapped]
            if a_before != b_before or a_after != b_after:
                return False
            if not a_before and not a_after:
                if (pre_a[prior] < pre_a[index]) != (pre_b[mapped] < pre_b[target]):
                    return False
        return True

    def search(index: int, cost: int, matched: int) -> None:
        nonlocal best
        if cost + relaxed_lower_bound(index) >= best:
            return
        if index == n:
            total = cost + (m - matched)
            if total < best:
                best = total
            return
        mapping[index] = -1
        search(index + 1, cost + 1, matched)
        for target in range(m):
            if used[target] or not compatible(index, target):
                continue
            used[target] = True
            mapping[index] = target
            search(index + 1, cost + (labels_a[index] != labels_b[target]), matched + 1)
            used[target] = False
        mapping[index] = -1

    search(0, 0, 0)
    return best
