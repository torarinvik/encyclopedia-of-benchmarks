"""Bounded highest-label pseudoflow reference using a normalized forest."""

MAX_NODES = 8
MAX_ARCS = 24
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_ARCS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CAPACITY = 100
MAX_RESULT = MAX_ARCS * MAX_CAPACITY
MAX_ITERATIONS = 512
SYMBOL = "hochbaum_pseudoflow_maxflow"


def _is_i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def expected_result(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(not _is_i64(value) for value in values)):
        return -1

    node_count, arc_count, source_raw, sink_raw = values[:4]
    if not (2 <= node_count <= MAX_NODES and 0 <= arc_count <= MAX_ARCS
            and 1 <= source_raw <= node_count and 1 <= sink_raw <= node_count
            and source_raw != sink_raw
            and len(values) == 4 + 3 * arc_count):
        return -1

    source, sink = source_raw - 1, sink_raw - 1
    ordinary = [v for v in range(node_count) if v != source and v != sink]
    local = {vertex: index for index, vertex in enumerate(ordinary)}
    count = len(ordinary)
    source_capacity = [0] * count
    sink_capacity = [0] * count
    direct_capacity = 0
    arcs = []

    for i in range(arc_count):
        u_raw, v_raw, cap = values[4 + 3 * i:7 + 3 * i]
        if not (1 <= u_raw <= node_count and 1 <= v_raw <= node_count
                and u_raw != v_raw and 0 <= cap <= MAX_CAPACITY):
            return -1
        u, v = u_raw - 1, v_raw - 1
        if u == source:
            if v == sink:
                direct_capacity += cap
            else:
                source_capacity[local[v]] += cap
        elif v == sink:
            sink_capacity[local[u]] += cap
        elif v == source or u == sink:
            return -1
        else:
            arcs.append((local[u], local[v], cap))

    weight = [source_capacity[i] - sink_capacity[i] for i in range(count)]
    flow = [0] * len(arcs)
    tree_edges = []
    root_edge = [True] * count
    labels = [1] * count
    ticket = list(range(count))
    next_ticket = count
    root_vertex = count

    def balances():
        result = weight[:]
        for edge_id, (u, v, _) in enumerate(arcs):
            result[u] -= flow[edge_id]
            result[v] += flow[edge_id]
        return result

    def tree_state():
        adjacency = [[] for _ in range(count + 1)]
        for vertex, attached in enumerate(root_edge):
            if attached:
                adjacency[root_vertex].append((vertex, -1))
                adjacency[vertex].append((root_vertex, -1))
        for edge_id in tree_edges:
            u, v, _ = arcs[edge_id]
            adjacency[u].append((v, edge_id))
            adjacency[v].append((u, edge_id))
        parent = [-2] * (count + 1)
        parent_edge = [-2] * (count + 1)
        branch_root = [-1] * count
        parent[root_vertex] = -1
        queue = [root_vertex]
        for u in queue:
            for v, edge_id in adjacency[u]:
                if parent[v] != -2:
                    continue
                parent[v] = u
                parent_edge[v] = edge_id
                branch_root[v] = v if u == root_vertex else branch_root[u]
                queue.append(v)
        if len(queue) != count + 1:
            return None
        members = {}
        for vertex, root in enumerate(branch_root):
            members.setdefault(root, []).append(vertex)
        return parent, parent_edge, branch_root, members

    def path_from_root(vertex, parent, parent_edge):
        steps = []
        cursor = vertex
        while cursor != root_vertex:
            previous = parent[cursor]
            steps.append((previous, cursor, parent_edge[cursor]))
            cursor = previous
        steps.reverse()
        return steps

    for _iteration in range(MAX_ITERATIONS):
        balance = balances()
        state = tree_state()
        if state is None:
            return -1
        parent, parent_edge, branch_root, members = state
        strong_roots = [root for root in members if balance[root] > 0]
        strong = [balance[branch_root[v]] > 0 for v in range(count)]
        has_strong_to_weak_residual = False
        for edge_id, (u, v, cap) in enumerate(arcs):
            if strong[u] and not strong[v] and cap - flow[edge_id] > 0:
                has_strong_to_weak_residual = True
            if strong[v] and not strong[u] and flow[edge_id] > 0:
                has_strong_to_weak_residual = True
        if not has_strong_to_weak_residual:
            cut = direct_capacity
            for vertex in range(count):
                if strong[vertex]:
                    cut += sink_capacity[vertex]
                else:
                    cut += source_capacity[vertex]
            for u, v, cap in arcs:
                if strong[u] and not strong[v]:
                    cut += cap
            return cut if 0 <= cut <= MAX_RESULT else -1

        strong_root = min(strong_roots, key=lambda root: (-labels[root], ticket[root], root))
        branch = members[strong_root]
        low_label = min(labels[v] for v in branch)
        low_nodes = sorted(v for v in branch if labels[v] == low_label)
        tree_set = set(tree_edges)
        candidates = []

        for tail in low_nodes:
            for edge_id, (u, v, cap) in enumerate(arcs):
                if edge_id in tree_set:
                    continue
                if u == tail and cap - flow[edge_id] > 0:
                    head = v
                    if branch_root[head] != strong_root and labels[head] == low_label - 1:
                        candidates.append((tail, edge_id, 0, head))
                if v == tail and flow[edge_id] > 0:
                    head = u
                    if branch_root[head] != strong_root and labels[head] == low_label - 1:
                        candidates.append((tail, edge_id, 1, head))

        if not candidates:
            relabel_nodes = []
            for vertex in low_nodes:
                children = [v for v in branch if parent[v] == vertex]
                if all(labels[child] >= low_label + 1 for child in children):
                    relabel_nodes.append(vertex)
            if not relabel_nodes:
                return -1
            relabel = relabel_nodes[0]
            old_label = labels[relabel]
            labels[relabel] = old_label + 1
            if relabel == strong_root:
                next_ticket += 1
                ticket[strong_root] = next_ticket
            continue

        tail, entering_id, direction, head = min(candidates)
        old_active = {root for root in strong_roots}
        old_labels = labels[:]

        strong_path_all = path_from_root(tail, parent, parent_edge)
        strong_path = strong_path_all[1:]
        weak_path_all = path_from_root(head, parent, parent_edge)
        weak_path = [(to, frm, edge_id) for frm, to, edge_id in reversed(weak_path_all[1:])]
        steps = strong_path + [(tail, head, entering_id)] + weak_path

        # The strong root edge is removed; the entering arc joins the branch
        # at the weak/target root. This inverts the strong path in the rooted
        # normalized tree, as in the paper's merger operation.
        root_edge[strong_root] = False
        tree_edges.append(entering_id)
        for vertex in [strong_root] + [to for _, to, _ in strong_path]:
            labels[vertex] = labels[head] + 1

        carry = balance[strong_root]
        for frm, to, edge_id in steps:
            u, v, cap = arcs[edge_id]
            residual = cap - flow[edge_id] if (frm, to) == (u, v) else flow[edge_id]
            pushed = min(carry, residual)
            if frm == u and to == v:
                flow[edge_id] += pushed
            else:
                flow[edge_id] -= pushed
            if residual < carry:
                if edge_id not in tree_edges:
                    return -1
                tree_edges.remove(edge_id)
                root_edge[frm] = True
                carry = pushed
            if carry == 0:
                break

        after_balance = balances()
        after_state = tree_state()
        if after_state is None:
            return -1
        _, _, after_roots, after_members = after_state
        for root in after_members:
            if after_balance[root] > 0 and (root not in old_active or labels[root] != old_labels[root]):
                next_ticket += 1
                ticket[root] = next_ticket

    return -1
