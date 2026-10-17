package segment_tree_update

import "core:c"

MAX_N :: 64
MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 259
MAX_TREE_LENGTH :: 128
VALUE_MIN :: i64(-1_000_000)
VALUE_MAX :: i64(1_000_000)
FNV_OFFSET :: u64(14695981039346656037)
FNV_PRIME :: u64(1099511628211)
MASK_63 :: u64(0x7fffffffffffffff)

query_sum :: proc "contextless" (tree: [^]i32, node, segment_left, segment_right, query_left, query_right: int) -> i32 {
    if query_left <= segment_left && segment_right <= query_right do return tree[node]
    if query_right < segment_left || segment_right < query_left do return 0
    middle := segment_left + (segment_right - segment_left) / 2
    return query_sum(tree, node * 2, segment_left, middle, query_left, query_right) +
        query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right)
}

hash_i64_word :: proc "contextless" (hash: u64, word: i64) -> u64 {
    bits := u64(word)
    result := hash
    for shift := 0; shift < 64; shift += 8 {
        result = (result ^ u64(u8(bits >> u32(shift)))) * FNV_PRIME
    }
    return result
}

@(export)
segment_tree_update_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_N do return -1
    n := int(input[0])
    if int(length) < n + 2 do return -1
    if input[n + 1] < 1 || input[n + 1] > MAX_OPERATIONS do return -1
    operation_count := int(input[n + 1])
    if int(length) != n + 2 + 3 * operation_count do return -1

    for index := 0; index < n; index += 1 {
        if input[index + 1] < VALUE_MIN || input[index + 1] > VALUE_MAX do return -1
    }
    operations_start := n + 2
    query_count := 0
    for operation := 0; operation < operation_count; operation += 1 {
        offset := operations_start + 3 * operation
        kind, first, second := input[offset], input[offset + 1], input[offset + 2]
        if kind == 0 {
            if first < 0 || first > second || second >= i64(n) do return -1
            query_count += 1
        } else if kind == 1 {
            if first < 0 || first >= i64(n) || second < VALUE_MIN || second > VALUE_MAX do return -1
        } else do return -1
    }
    if query_count == 0 do return -1

    power := 1
    for power < n do power *= 2
    tree: [MAX_TREE_LENGTH]i32
    for index := 0; index < MAX_TREE_LENGTH; index += 1 { tree[index] = 0 }
    for index := 0; index < n; index += 1 { tree[power + index] = i32(input[index + 1]) }
    for node := power - 1; node > 0; node -= 1 { tree[node] = tree[node * 2] + tree[node * 2 + 1] }

    hash := hash_i64_word(FNV_OFFSET, i64(query_count))
    for operation := 0; operation < operation_count; operation += 1 {
        offset := operations_start + 3 * operation
        kind, first, second := input[offset], input[offset + 1], input[offset + 2]
        if kind == 0 {
            sum := query_sum(&tree[0], 1, 1, power, int(first) + 1, int(second) + 1)
            hash = hash_i64_word(hash, i64(sum))
        } else {
            node := power + int(first)
            tree[node] = i32(second)
            for node > 1 {
                node /= 2
                tree[node] = tree[node * 2] + tree[node * 2 + 1]
            }
        }
    }
    return i64(hash & MASK_63)
}
