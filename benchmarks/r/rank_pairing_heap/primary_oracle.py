"""Reference model for the Type-1 rank-pairing half-tree operations."""

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
    if (not 0 <= count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * count
            or len(values) > MAX_INPUT_VALUES):
        return None
    return count


def expected_output(values, input_is_null=False, input_length=None):
    operation_count = _operation_count(values, input_is_null, input_length)
    if operation_count is None:
        return INVALID_RESULT

    keys = [0] * MAX_OPERATIONS
    items = [-1] * MAX_OPERATIONS
    ranks = [0] * MAX_OPERATIONS
    left = [-1] * MAX_OPERATIONS
    right = [-1] * MAX_OPERATIONS
    parent = [-2] * MAX_OPERATIONS  # -2 unused, -1 a half-tree root.
    alive = [False] * MAX_OPERATIONS
    item_nodes = [-1] * MAX_ITEMS
    active = [False] * MAX_ITEMS
    node_count = 0

    def rank_of(node):
        return -1 if node < 0 else ranks[node]

    def roots():
        return [node for node in range(node_count)
                if alive[node] and parent[node] == -1]

    def minimum_root():
        candidates = roots()
        if not candidates:
            return -1
        return min(candidates, key=lambda node: (keys[node], items[node], node))

    def fair_link(first, second):
        winner, loser = sorted((first, second),
                               key=lambda node: (keys[node], items[node], node))
        old_left = left[winner]
        left[winner] = loser
        parent[loser] = winner
        right[loser] = old_left
        if old_left >= 0:
            parent[old_left] = loser
        ranks[winner] += 1

    def consolidate_fair_roots():
        while True:
            roots_by_rank = {}
            for node in roots():
                roots_by_rank.setdefault(ranks[node], []).append(node)
            duplicate_ranks = [rank for rank, group in roots_by_rank.items()
                               if len(group) >= 2]
            if not duplicate_ranks:
                return
            rank = min(duplicate_ranks)
            first, second = sorted(roots_by_rank[rank])[:2]
            fair_link(first, second)

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
            left[node] = right[node] = -1
            parent[node] = -1
            alive[node] = True
            item_nodes[item_id] = node
            active[item_id] = True

        elif opcode == 2:
            if (not 0 <= item_id < MAX_ITEMS or not active[item_id]
                    or not 0 <= value <= MAX_KEY or node_count >= MAX_OPERATIONS):
                return INVALID_RESULT
            node = item_nodes[item_id]
            if value >= keys[node]:
                return INVALID_RESULT
            keys[node] = value
            if parent[node] >= 0:
                old_parent = parent[node]
                next_sibling = right[node]
                if left[old_parent] == node:
                    left[old_parent] = next_sibling
                else:
                    right[old_parent] = next_sibling
                if next_sibling >= 0:
                    parent[next_sibling] = old_parent
                parent[node] = -1
                right[node] = -1
                ranks[node] = rank_of(left[node]) + 1

                ancestor = old_parent
                while ancestor >= 0:
                    if parent[ancestor] < 0:
                        ranks[ancestor] = rank_of(left[ancestor]) + 1
                        break
                    left_rank = rank_of(left[ancestor])
                    right_rank = rank_of(right[ancestor])
                    new_rank = (max(left_rank, right_rank) if left_rank != right_rank
                                else left_rank + 1)
                    if new_rank >= ranks[ancestor]:
                        break
                    ranks[ancestor] = new_rank
                    ancestor = parent[ancestor]

        elif opcode == 3:
            if item_id != 0 or value != 0:
                return INVALID_RESULT
            node = minimum_root()
            if node < 0:
                return INVALID_RESULT
            removed_item = items[node]
            result += (operation_index + 1) * (keys[node] + 1) + removed_item
            active[removed_item] = False
            item_nodes[removed_item] = -1

            child = left[node]
            while child >= 0:
                next_sibling = right[child]
                right[child] = -1
                parent[child] = -1
                ranks[child] = rank_of(left[child]) + 1
                child = next_sibling
            alive[node] = False
            parent[node] = -2
            left[node] = right[node] = -1
            items[node] = -1
            consolidate_fair_roots()

        elif opcode == 4:
            if item_id != 0 or value != 0:
                return INVALID_RESULT
            node = minimum_root()
            if node < 0:
                return INVALID_RESULT
            result += (operation_index + 1) * (keys[node] + 1) + items[node]

        else:
            return INVALID_RESULT

    return result
