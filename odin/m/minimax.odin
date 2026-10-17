package minimax

import "core:c"

evaluate :: proc(values: [^]i64, index, depth, height: int, maximizing: bool) -> i64 {
    if depth == height do return values[2 + index]
    left := evaluate(values, index * 2, depth + 1, height, !maximizing)
    right := evaluate(values, index * 2 + 1, depth + 1, height, !maximizing)
    if maximizing do return max(left, right)
    return min(left, right)
}

@(export)
minimax :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 34 do return -2147483649
    leaf_count := values[0]
    first_turn_is_max := values[1]
    if leaf_count < 1 || leaf_count > 32 || (leaf_count & (leaf_count - 1)) != 0 do return -2147483649
    if (first_turn_is_max != 0 && first_turn_is_max != 1) || length != c.size_t(2 + leaf_count) do return -2147483649
    for leaf := 0; leaf < int(leaf_count); leaf += 1 {
        if values[2 + leaf] < -2_147_483_648 || values[2 + leaf] > 2_147_483_647 do return -2147483649
    }
    height := 0
    width := int(leaf_count)
    for width > 1 { width /= 2; height += 1 }
    return evaluate(values, 0, 0, height, first_turn_is_max == 1)
}
