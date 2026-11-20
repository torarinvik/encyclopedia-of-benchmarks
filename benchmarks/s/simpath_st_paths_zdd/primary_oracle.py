"""Frontier/mate construction of a reduced ZDD for undirected s-t paths."""

MAX_N = 8
MAX_M = 9
MAX_VALID_INPUT_LENGTH = 22
MAX_PARSEABLE_INPUT_LENGTH = 23
MAX_FRONTIER_STATES = 1023
MAX_ZDD_NODES = 511
PATH_COUNT_RADIX = 2048
WORKSPACE_BYTES = 65_536


def _parse(values):
    if (not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, source, target = values[:4]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or source == target:
        return None
    if not (0 <= source < n and 0 <= target < n) or len(values) != 4 + 2 * m:
        return None
    edges = []
    seen = set()
    for i in range(m):
        u, v = values[4 + 2 * i:6 + 2 * i]
        if not (0 <= u < v < n) or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges, source, target


def _degree(mate, vertex):
    value = mate[vertex]
    if value == vertex + 1:
        return 0
    if value == 0:
        return 2
    return 1


def _frontier_transition(mate, edge, selected, edge_index, last, source, target):
    """Return (next_state, terminal_id), or None for a pruned branch."""
    u, v = edge
    result = list(mate)
    if selected:
        du, dv = _degree(result, u), _degree(result, v)
        if du == 2 or dv == 2:
            return None
        if (u in (source, target) and du == 1) or (v in (source, target) and dv == 1):
            return None
        mu, mv = result[u], result[v]
        if mu == v + 1 and mv == u + 1:
            return None
        if ((mu == source + 1 and mv == target + 1)
                or (mu == target + 1 and mv == source + 1)):
            for w in range(len(result)):
                if w not in (source, target, u, v) and _degree(result, w) == 1:
                    return None
            return None, 1
        result[u] = 0
        result[v] = 0
        result[mu - 1] = mv
        result[mv - 1] = mu

    for w, final_incident_edge in enumerate(last):
        if final_incident_edge != edge_index:
            continue
        degree = _degree(result, w)
        if w in (source, target):
            if degree == 0:
                return None
        elif degree == 1:
            return None
        if w not in (source, target):
            # Once a nonterminal vertex leaves the frontier its degree-0 or
            # degree-2 state has no effect on any suffix decision.
            result[w] = w + 1
    return tuple(result), None


def _build_frontier_zdd(n, edges, source, target):
    last = [-1] * n
    for edge_index, (u, v) in enumerate(edges):
        last[u] = last[v] = edge_index

    nodes = [None, None]  # IDs 0 and 1 are the zero and one terminals.
    unique = {}
    memo = {}

    def make(edge_index, low, high):
        if high == 0:  # ZDD zero-suppression rule.
            return low
        key = edge_index, low, high
        found = unique.get(key)
        if found is not None:
            return found
        identifier = len(nodes)
        nodes.append(key)
        unique[key] = identifier
        return identifier

    def visit(edge_index, mate):
        if edge_index == len(edges):
            return 0
        key = edge_index, mate
        if key in memo:
            return memo[key]
        low_state = _frontier_transition(
            mate, edges[edge_index], False, edge_index, last, source, target)
        low = 0 if low_state is None else visit(edge_index + 1, low_state[0])

        high_state = _frontier_transition(
            mate, edges[edge_index], True, edge_index, last, source, target)
        if high_state is None:
            high = 0
        elif high_state[1] == 1:
            high = 1
        else:
            high = visit(edge_index + 1, high_state[0])

        result = make(edge_index, low, high)
        memo[key] = result
        return result

    root = visit(0, tuple(range(1, n + 1)))
    reachable = set()
    stack = [root]
    while stack:
        identifier = stack.pop()
        if identifier <= 1 or identifier in reachable:
            continue
        reachable.add(identifier)
        _, low, high = nodes[identifier]
        stack.extend((low, high))

    path_counts = [0, 1] + [0] * (len(nodes) - 2)
    for identifier in range(2, len(nodes)):
        _, low, high = nodes[identifier]
        path_counts[identifier] = path_counts[low] + path_counts[high]
    return len(reachable), path_counts[root]


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, edges, source, target = parsed
    node_count, path_count = _build_frontier_zdd(n, edges, source, target)
    if node_count > MAX_ZDD_NODES or path_count >= PATH_COUNT_RADIX:
        return -1
    return node_count * PATH_COUNT_RADIX + path_count
