"""Skew-binomial-forest reference for the bounded queue workload."""

INVALID_RESULT = -1
MAX_OPERATIONS = 64
MAX_ITEMS = 32
MAX_KEY = 1_000_000
MAX_INPUT_VALUES = 193
MAX_PARSEABLE_INPUT_VALUES = 194


def _operation_count(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if (not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count
            or len(values) > MAX_INPUT_VALUES):
        return None
    return count


def expected_output(values, input_is_null=False, input_length=None):
    operation_count = _operation_count(values, input_is_null, input_length)
    if operation_count is None:
        return INVALID_RESULT

    keys = [0] * MAX_OPERATIONS
    item_ids = [-1] * MAX_OPERATIONS
    serials = [0] * MAX_OPERATIONS
    ranks = [0] * MAX_OPERATIONS
    first_child = [-1] * MAX_OPERATIONS
    next_sibling = [-1] * MAX_OPERATIONS
    parents = [-2] * MAX_OPERATIONS
    alive = [False] * MAX_OPERATIONS
    item_nodes = [-1] * MAX_ITEMS
    active = [False] * MAX_ITEMS
    node_count = 0
    insertion_serial = 0

    def less(first, second):
        return (keys[first], serials[first], item_ids[first], first) < (
            keys[second], serials[second], item_ids[second], second)

    def roots_by_rank():
        return sorted((node for node in range(node_count)
                       if alive[node] and parents[node] == -1),
                      key=lambda node: (ranks[node], serials[node], node))

    def simple_link(first, second):
        winner, loser = (first, second) if less(first, second) else (second, first)
        next_sibling[loser] = first_child[winner]
        first_child[winner] = loser
        parents[loser] = winner
        ranks[winner] += 1
        return winner

    def skew_link(singleton, first, second):
        # The singleton participates as the rank-zero tree in a type-A or
        # type-B skew link. A total order pins the otherwise arbitrary ties.
        if less(singleton, first) and less(singleton, second):
            winner = singleton
            first_child[winner] = first
            next_sibling[first] = second
            next_sibling[second] = -1
            parents[first] = parents[second] = winner
        else:
            winner = first if less(first, second) else second
            loser = second if winner == first else first
            old_children = first_child[winner]
            first_child[winner] = singleton
            next_sibling[singleton] = loser
            next_sibling[loser] = old_children
            parents[singleton] = parents[loser] = winner
        parents[winner] = -1
        # Both skew-link forms create rank r+1 from two rank-r trees. In
        # type A, the winner is a rank-zero singleton, so assignment is not
        # equivalent to incrementing its old rank.
        ranks[winner] = ranks[first] + 1
        return winner

    def normalize_equal_ranks(root_nodes):
        buckets = {}
        for root in sorted(root_nodes, key=lambda node: (ranks[node], serials[node], node)):
            current = root
            while ranks[current] in buckets:
                previous = buckets.pop(ranks[current])
                current = simple_link(previous, current)
            buckets[ranks[current]] = current
        return sorted(buckets.values(), key=lambda node: (ranks[node], serials[node], node))

    def insert_singleton(node):
        # The insertion rule inspects the existing queue before adding the
        # singleton. Exclude it while selecting the possible duplicate pair.
        parents[node] = -2
        next_sibling[node] = -1
        roots = roots_by_rank()
        if len(roots) >= 2 and ranks[roots[0]] == ranks[roots[1]]:
            first, second = roots[0], roots[1]
            skew_link(node, first, second)
        else:
            parents[node] = -1

    result = 0
    for operation_index in range(operation_count):
        offset = 1 + 3 * operation_index
        opcode, item_id, key = values[offset:offset + 3]

        if opcode == 1:
            if (not 0 <= item_id < MAX_ITEMS or not 0 <= key <= MAX_KEY
                    or active[item_id] or node_count >= MAX_OPERATIONS):
                return INVALID_RESULT
            node = node_count
            node_count += 1
            keys[node] = key
            item_ids[node] = item_id
            serials[node] = insertion_serial
            insertion_serial += 1
            ranks[node] = 0
            first_child[node] = next_sibling[node] = -1
            parents[node] = -1
            alive[node] = True
            item_nodes[item_id] = node
            active[item_id] = True
            insert_singleton(node)

        elif opcode in (2, 3):
            if item_id != 0 or key != 0:
                return INVALID_RESULT
            roots = roots_by_rank()
            if not roots:
                return INVALID_RESULT
            node = min(roots, key=lambda candidate: (
                keys[candidate], serials[candidate], item_ids[candidate], candidate))
            result += (operation_index + 1) * (keys[node] + 1) + item_ids[node]
            if opcode == 2:
                continue

            active[item_ids[node]] = False
            item_nodes[item_ids[node]] = -1
            children = []
            child = first_child[node]
            while child >= 0:
                following = next_sibling[child]
                parents[child] = -1
                next_sibling[child] = -1
                children.append(child)
                child = following
            alive[node] = False
            parents[node] = -2
            item_ids[node] = -1
            first_child[node] = next_sibling[node] = -1

            zero_rank_children = sorted(
                (child for child in children if ranks[child] == 0),
                key=lambda child: (serials[child], child))
            positive_rank_children = [child for child in children if ranks[child] > 0]
            child_set = set(children)
            remaining_roots = [root for root in roots_by_rank() if root not in child_set]
            normalize_equal_ranks(remaining_roots + positive_rank_children)
            for singleton in zero_rank_children:
                insert_singleton(singleton)

        else:
            return INVALID_RESULT

    return result
