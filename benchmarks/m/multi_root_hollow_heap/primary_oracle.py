"""Array-indexed reference for the multi-root hollow heap operation profile."""

INVALID_RESULT = -1
MAX_OPERATIONS = 64
MAX_ITEMS = 32
MAX_KEY = 1_000_000
MAX_INPUT_VALUES = 193
MAX_PARSEABLE_INPUT_VALUES = 194


def _frame(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * operation_count
            or len(values) > MAX_INPUT_VALUES):
        return None
    return operation_count


def expected_output(values, input_is_null=False, input_length=None):
    operation_count = _frame(values, input_is_null, input_length)
    if operation_count is None:
        return INVALID_RESULT

    keys = [0] * MAX_OPERATIONS
    items = [-1] * MAX_OPERATIONS  # -1 marks a hollow node.
    ranks = [0] * MAX_OPERATIONS
    parents = [-2] * MAX_OPERATIONS  # -2 unused, -1 root, otherwise parent index.
    alive = [False] * MAX_OPERATIONS
    item_nodes = [-1] * MAX_ITEMS
    active = [False] * MAX_ITEMS
    node_count = 0

    def minimum_root():
        roots = [node for node in range(node_count)
                 if alive[node] and parents[node] == -1 and items[node] >= 0]
        if not roots:
            return -1
        return min(roots, key=lambda node: (keys[node], items[node], node))

    def destroy_hollow_roots_and_consolidate():
        while True:
            hollow_roots = [node for node in range(node_count)
                            if alive[node] and parents[node] == -1 and items[node] == -1]
            if not hollow_roots:
                break
            hollow = min(hollow_roots)
            for child in range(node_count):
                if alive[child] and parents[child] == hollow:
                    parents[child] = -1
            alive[hollow] = False
            parents[hollow] = -2

        while True:
            roots_by_rank = {}
            for node in range(node_count):
                if alive[node] and parents[node] == -1 and items[node] >= 0:
                    roots_by_rank.setdefault(ranks[node], []).append(node)
            duplicate_ranks = [rank for rank, roots in roots_by_rank.items()
                               if len(roots) >= 2]
            if not duplicate_ranks:
                return
            rank = min(duplicate_ranks)
            first, second = sorted(roots_by_rank[rank])[:2]
            winner, loser = sorted((first, second),
                                   key=lambda node: (keys[node], items[node], node))
            parents[loser] = winner
            ranks[winner] += 1

    result = 0
    for operation_index in range(operation_count):
        offset = 1 + 3 * operation_index
        opcode, item_id, value = values[offset:offset + 3]

        if opcode == 1:
            if (not 0 <= item_id < MAX_ITEMS or not 0 <= value <= MAX_KEY
                    or active[item_id] or node_count >= MAX_OPERATIONS):
                return INVALID_RESULT
            node = node_count
            node_count += 1
            keys[node] = value
            items[node] = item_id
            ranks[node] = 0
            parents[node] = -1
            alive[node] = True
            item_nodes[item_id] = node
            active[item_id] = True

        elif opcode == 2:
            if (not 0 <= item_id < MAX_ITEMS or not active[item_id]
                    or not 0 <= value <= MAX_KEY or node_count >= MAX_OPERATIONS):
                return INVALID_RESULT
            old = item_nodes[item_id]
            if value >= keys[old]:
                return INVALID_RESULT
            new = node_count
            node_count += 1
            old_rank = ranks[old]
            items[old] = -1
            keys[new] = value
            items[new] = item_id
            ranks[new] = max(0, old_rank - 2)
            parents[new] = -1
            alive[new] = True
            for child in range(node_count - 1):
                if (alive[child] and parents[child] == old
                        and ranks[child] < ranks[new]):
                    parents[child] = new
            item_nodes[item_id] = new

        elif opcode == 3:
            if item_id != 0 or value != 0:
                return INVALID_RESULT
            node = minimum_root()
            if node < 0:
                return INVALID_RESULT
            item_id = items[node]
            active[item_id] = False
            item_nodes[item_id] = -1
            items[node] = -1
            result += (operation_index + 1) * (keys[node] + 1) + item_id
            destroy_hollow_roots_and_consolidate()

        elif opcode == 4:
            if item_id != 0 or value != 0:
                return INVALID_RESULT
            node = minimum_root()
            if node < 0:
                return INVALID_RESULT
            result += (operation_index + 1) * (keys[node] + 1) + items[node]

        elif opcode == 5:
            if (not 0 <= item_id < MAX_ITEMS or value != 0 or not active[item_id]):
                return INVALID_RESULT
            node = item_nodes[item_id]
            was_minimum = node == minimum_root()
            active[item_id] = False
            item_nodes[item_id] = -1
            items[node] = -1
            if was_minimum:
                destroy_hollow_roots_and_consolidate()

        else:
            return INVALID_RESULT

    return result
