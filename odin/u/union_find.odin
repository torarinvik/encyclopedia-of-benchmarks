package union_find

import "core:c"

MAX_ITEMS :: 256
MAX_OPERATIONS :: 512
MAX_INPUT_VALUES :: 2 + 3 * MAX_OPERATIONS
OBSERVED_OFFSET :: i64(1_000_003)

find_root :: proc "contextless" (parent: [^]i64, item: int) -> int {
    current := item
    for parent[current] != i64(current) {
        parent[current] = parent[int(parent[current])]
        current = int(parent[current])
    }
    return current
}

@(export)
union_find_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES do return -1
    item_count_value := values[0]
    operation_count_value := values[1]
    if item_count_value < 1 || item_count_value > MAX_ITEMS do return -1
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
    item_count := int(item_count_value)
    operation_count := int(operation_count_value)
    if int(length) != 2 + 3 * operation_count do return -1

    for operation := 0; operation < operation_count; operation += 1 {
        position := 2 + 3 * operation
        opcode := values[position]
        first := values[position + 1]
        second := values[position + 2]
        if opcode == 0 || opcode == 1 {
            if first < 0 || first >= item_count_value || second < 0 || second >= item_count_value do return -1
        } else if opcode == 2 {
            if first != 0 || second != 0 do return -1
        } else {
            return -1
        }
    }

    parent: [MAX_ITEMS]i64
    set_size: [MAX_ITEMS]i64
    for i := 0; i < item_count; i += 1 {
        parent[i] = i64(i)
        set_size[i] = 1
    }
    components := item_count
    connected_pairs := i64(0)
    checksum := i64(0)
    for operation := 0; operation < operation_count; operation += 1 {
        position := 2 + 3 * operation
        opcode := values[position]
        first := int(values[position + 1])
        second := int(values[position + 2])
        observed := i64(0)
        if opcode == 0 {
            first_root := find_root(&parent[0], first)
            second_root := find_root(&parent[0], second)
            if first_root != second_root {
                connected_pairs += set_size[first_root] * set_size[second_root]
                if set_size[first_root] < set_size[second_root] {
                    parent[first_root] = i64(second_root)
                    set_size[second_root] += set_size[first_root]
                } else {
                    parent[second_root] = i64(first_root)
                    set_size[first_root] += set_size[second_root]
                }
                components -= 1
                observed = 1
            }
        } else if opcode == 1 {
            if find_root(&parent[0], first) == find_root(&parent[0], second) do observed = 1
        } else {
            observed = i64(components)
        }
        checksum += i64(operation + 1) * (observed + OBSERVED_OFFSET)
    }
    return checksum + connected_pairs
}
