"""Permutation-graph minimal-dominating-set count via the source five-tuple DAG."""

from __future__ import annotations

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_RESULT = 255
WORKSPACE_BYTES = 1_048_576
_BOTTOM = MAX_N


def _case(i: int, j: int, k: int, top: list[int]) -> int:
    a, b, c = top[i], top[j], top[k]
    if a < b < c:
        return 1
    if a < c < b:
        return 2
    if b < a < c:
        return 3
    if b < c < a:
        return 4
    if c < a < b:
        return 5
    return 0


def _make_graph(top: list[int]) -> tuple[list[list[bool]], list[int]]:
    n = len(top)
    adjacent = [[False] * n for _ in range(n)]
    top_vertex = [0] * n
    for x, rank in enumerate(top):
        top_vertex[rank] = x
        adjacent[x][x] = True
    for x in range(n):
        for y in range(x + 1, n):
            adjacent[x][y] = adjacent[y][x] = top[x] > top[y]
    return adjacent, top_vertex


def _dominated(x: int, selected: tuple[int, ...], adjacent: list[list[bool]]) -> bool:
    return any(adjacent[u][x] for u in selected)


def _private_min_rank(
    x: int, selected: tuple[int, ...], adjacent: list[list[bool]], top: list[int]
) -> int | None:
    best_rank: int | None = None
    for y in range(len(top)):
        if not adjacent[x][y]:
            continue
        if any(u != x and adjacent[u][y] for u in selected):
            continue
        if best_rank is None or top[y] < top[best_rank]:
            best_rank = y
    return best_rank


def _irredundant(selected: tuple[int, ...], adjacent: list[list[bool]]) -> bool:
    for x in selected:
        if not any(
            adjacent[x][y]
            and not any(u != x and adjacent[u][y] for u in selected)
            for y in range(len(adjacent))
        ):
            return False
    return True


def _initial(
    i: int, j: int, k: int, r: int, s: int,
    top: list[int], adjacent: list[list[bool]],
) -> bool:
    n = len(top)
    if r != n or not _irredundant((i, j, k), adjacent):
        return False
    case = _case(i, j, k, top)
    if case == 1:
        return (not any(y < i and top[y] < top[i] for y in range(n))
                and s == _private_min_rank(i, (i, j, k), adjacent, top))
    if case == 2:
        return (s == n and not any(
            top[y] < top[k] and y < j and not _dominated(y, (i, j, k), adjacent)
            for y in range(n)
        ))
    if case == 3:
        return (not any(top[y] < top[j] and y < i for y in range(n))
                and s == _private_min_rank(j, (i, j, k), adjacent, top))
    if case == 4:
        return (s == n and not any(
            top[y] < top[j] and y < i and not _dominated(y, (i, j, k), adjacent)
            for y in range(n)
        ))
    if case == 5:
        return (not any(top[y] < top[k] and y < i for y in range(n))
                and s == _private_min_rank(k, (i, j, k), adjacent, top))
    return False


def _regular(
    i: int, j: int, k: int, r: int, s: int,
    top: list[int], adjacent: list[list[bool]],
) -> bool:
    n = len(top)
    case = _case(i, j, k, top)
    if not _irredundant((i, j, k), adjacent):
        return False
    if case in (1, 2, 3, 4):
        if not 0 <= r < i:
            return False
    elif case == 5:
        if r != n:
            return False
    else:
        return False
    if case in (2, 4):
        return s == n
    if not 0 <= s < n:
        return False
    if case == 1:
        return adjacent[i][s] and not any(adjacent[u][s] for u in (r, j, k))
    if case == 3:
        return adjacent[j][s] and not any(adjacent[u][s] for u in (r, i, k))
    return adjacent[k][s] and not adjacent[i][s] and not adjacent[j][s]


def _is_final(
    i: int, j: int, k: int, r: int, s: int,
    top: list[int], adjacent: list[list[bool]],
) -> bool:
    n = len(top)
    selected = (i, j, k) if r == n else (r, i, j, k)
    return all(
        not (i < y and top[i] < top[y]) or _dominated(y, selected, adjacent)
        for y in range(n)
    )


def _next_state(
    i: int, j: int, k: int, r: int, s: int, ell: int,
    top: list[int], top_vertex: list[int], adjacent: list[list[bool]],
) -> tuple[int, int, int, int, int] | None:
    n = len(top)
    case = _case(j, k, ell, top)
    if case == 0:
        return None
    selected = (i, j, k, ell) if r == n else (r, i, j, k, ell)
    if not _irredundant(selected, adjacent):
        return None
    if s != n and top[ell] <= top[s]:
        return None
    if not adjacent[j][k]:
        if any(
            i < y < j and top[i] < top[y] < top[j]
            and not _dominated(y, selected, adjacent)
            for y in range(n)
        ):
            return None
    if adjacent[i][k]:
        if any(
            j < y < k and top[j] < top[y] < top[ell]
            and not _dominated(y, selected, adjacent)
            for y in range(n)
        ):
            return None

    new_r = n if case == 5 else top_vertex[max(top[r] if r != n else top[i], top[i])]
    if case in (2, 4):
        new_s = n
    elif s != n and min(top[i], top[j], top[k]) == min(top[j], top[k], top[ell]):
        new_s = s
    else:
        y = min((j, k, ell), key=lambda x: top[x])
        new_s = _private_min_rank(y, selected, adjacent, top)
        if new_s is None:
            return None
    if not _regular(j, k, ell, new_r, new_s, top, adjacent):
        return None
    return (j, k, ell, new_r, new_s)


def _index(state: tuple[int, int, int, int, int], base: int) -> int:
    value = 0
    for part in state:
        value = value * base + part
    return value


def _small_set_is_minimal(mask: int, adjacency_masks: list[int], full: int) -> bool:
    covered = 0
    for u in range(len(adjacency_masks)):
        if mask & (1 << u):
            covered |= adjacency_masks[u]
    if covered != full:
        return False
    for u in range(len(adjacency_masks)):
        bit = 1 << u
        if mask & bit:
            remaining = mask ^ bit
            remainder_cover = 0
            for v in range(len(adjacency_masks)):
                if remaining & (1 << v):
                    remainder_cover |= adjacency_masks[v]
            if remainder_cover == full:
                return False
    return True


def _dag_count(top: list[int]) -> int:
    n = len(top)
    base = n + 1
    adjacent, top_vertex = _make_graph(top)
    ways = [0] * (base ** 5)
    total = 0
    for i in range(n - 3, -1, -1):
        for j in range(i + 1, n - 1):
            for k in range(j + 1, n):
                case = _case(i, j, k, top)
                if case == 0 or not _irredundant((i, j, k), adjacent):
                    continue
                r_values = list(range(i)) + [n]
                for r in r_values:
                    for s in range(base):
                        state = (i, j, k, r, s)
                        if not (_initial(i, j, k, r, s, top, adjacent)
                                or _regular(i, j, k, r, s, top, adjacent)):
                            continue
                        count = int(_is_final(i, j, k, r, s, top, adjacent))
                        for ell in range(k + 1, n):
                            target = _next_state(
                                i, j, k, r, s, ell, top, top_vertex, adjacent
                            )
                            if target is not None:
                                count += ways[_index(target, base)]
                        ways[_index(state, base)] = count
                        if _initial(i, j, k, r, s, top, adjacent):
                            total += count

    adjacency_masks = []
    for x in range(n):
        mask = 0
        for y in range(n):
            if adjacent[x][y]:
                mask |= 1 << y
        adjacency_masks.append(mask)
    full = (1 << n) - 1
    for size in (1, 2):
        for mask in range(1, 1 << n):
            if mask.bit_count() == size and _small_set_is_minimal(mask, adjacency_masks, full):
                total += 1
    return total


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if values is None or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return -1
    top = list(values[1:])
    if any(rank < 0 or rank >= n for rank in top) or len(set(top)) != n:
        return -1
    return _dag_count(top)
