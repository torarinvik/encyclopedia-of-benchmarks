package range_parallel_unionfind

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_LEVELS :: 6
MAX_INPUT_VALUES :: 2 + MAX_N + 3 * MAX_Q
MODULUS :: i64(998244353)

normalize :: proc(value: i64) -> i64 {
    reduced := value % MODULUS
    if reduced < 0 do return reduced + MODULUS
    return reduced
}

find_root :: proc "contextless" (parent: [^]int, level, item: int) -> int {
    index := level * MAX_N + item
    if parent[index] != item {
        parent[index] = find_root(parent, level, parent[index])
    }
    return parent[index]
}

merge_inner :: proc(level, left, right: int, parent, set_size: [^]int,
    weight: [^]i64, pair_sum: ^i64) {
    root_left := find_root(parent, level, left)
    root_right := find_root(parent, level, right)
    if root_left == root_right do return
    left_index := level * MAX_N + root_left
    right_index := level * MAX_N + root_right
    if set_size[left_index] < set_size[right_index] {
        temporary := root_left
        root_left = root_right
        root_right = temporary
        left_index = level * MAX_N + root_left
        right_index = level * MAX_N + root_right
    }
    parent[level * MAX_N + root_right] = root_left
    set_size[left_index] += set_size[right_index]
    if level == 0 {
        pair_sum^ = normalize(pair_sum^ + weight[root_left] * weight[root_right])
        weight[root_left] = normalize(weight[root_left] + weight[root_right])
        return
    }
    half := 1 << (level - 1)
    merge_inner(level - 1, left, right, parent, set_size, weight, pair_sum)
    merge_inner(level - 1, left + half, right + half, parent, set_size, weight, pair_sum)
}

floor_log2 :: proc(value: int) -> int {
    level := 0
    remaining := value
    for remaining > 1 {
        remaining >>= 1
        level += 1
    }
    return level
}

merge_ranges :: proc(length, left, right: int, parent, set_size: [^]int,
    weight: [^]i64, pair_sum: ^i64) {
    if length == 0 do return
    level := floor_log2(length - 1)
    block := 1 << level
    merge_inner(level, left, right, parent, set_size, weight, pair_sum)
    merge_inner(level, left + length - block, right + length - block,
                parent, set_size, weight, pair_sum)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
range_parallel_unionfind :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 6 || length > MAX_INPUT_VALUES do return -1
    n_value := input[0]
    q_value := input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q do return -1
    n := int(n_value)
    q := int(q_value)
    if length != c.size_t(2 + n + 3 * q) do return -1
    for item := 0; item < n; item += 1 {
        if input[2 + item] < 0 || input[2 + item] >= MODULUS do return -1
    }
    operations_at := 2 + n
    for operation := 0; operation < q; operation += 1 {
        position := operations_at + 3 * operation
        span := input[position]
        left := input[position + 1]
        right := input[position + 2]
        if span < 0 || span > n_value || left < 0 || right < 0 ||
           left > n_value - span || right > n_value - span do return -1
    }
    required := 8 * q
    if output == nil || capacity < c.size_t(required) do return -2

    parent: [MAX_LEVELS * MAX_N]int
    set_size: [MAX_LEVELS * MAX_N]int
    weight: [MAX_N]i64
    for level := 0; level < MAX_LEVELS; level += 1 {
        block := 1 << level
        if block > n do break
        for start := 0; start <= n - block; start += 1 {
            index := level * MAX_N + start
            parent[index] = start
            set_size[index] = 1
        }
    }
    for item := 0; item < n; item += 1 do weight[item] = input[2 + item]
    pair_sum := i64(0)
    for operation := 0; operation < q; operation += 1 {
        position := operations_at + 3 * operation
        merge_ranges(int(input[position]), int(input[position + 1]), int(input[position + 2]),
                     &parent[0], &set_size[0], &weight[0], &pair_sum)
        store_i64_le(output, 8 * operation, pair_sum)
    }
    return i64(required)
}
