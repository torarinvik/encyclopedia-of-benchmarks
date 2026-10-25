"""Independent leaf-routing oracle for the bounded Rodinia B+ tree profile."""


def rodinia_bplus_tree(values):
    if not isinstance(values, (list, tuple)) or len(values) < 7 or len(values) > 31:
        return -1
    left_count, right_count, query_count = values[:3]
    if any(not isinstance(x, int) or isinstance(x, bool) for x in (left_count, right_count, query_count)):
        return -1
    if not (1 <= left_count <= 3 and 1 <= right_count <= 3 and 1 <= query_count <= 16):
        return -1
    if len(values) != 3 + 2 * (left_count + right_count) + query_count:
        return -1
    cursor = 3
    leaves = []
    for count in (left_count, right_count):
        leaf = []
        for _ in range(count):
            key, record_value = values[cursor:cursor + 2]
            cursor += 2
            if (not isinstance(key, int) or isinstance(key, bool) or not -1_000_000 <= key <= 1_000_000
                    or not isinstance(record_value, int) or isinstance(record_value, bool)
                    or not 0 <= record_value <= 1_000_000):
                return -1
            if leaf and key <= leaf[-1][0]:
                return -1
            leaf.append((key, record_value))
        leaves.append(leaf)
    if leaves[0][-1][0] >= leaves[1][0][0]:
        return -1
    answer = 0
    for query_index, query in enumerate(values[cursor:]):
        if not isinstance(query, int) or isinstance(query, bool) or not -1_000_000 <= query <= 1_000_000:
            return -1
        selected_leaf = leaves[0] if query < leaves[1][0][0] else leaves[1]
        record_value = next((value for key, value in selected_leaf if key == query), None)
        if record_value is not None:
            answer += (query_index + 1) * (record_value + 1)
    return answer
