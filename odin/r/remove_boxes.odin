package remove_boxes

import "core:c"

MAX_BOXES :: 18
MAX_PARSEABLE_LENGTH :: MAX_BOXES + 2
MAX_MEMO :: MAX_BOXES * MAX_BOXES * (MAX_BOXES + 1)

solve_boxes :: proc(left, right, carry: int, colors, counts, memo: [^]i64) -> i64 {
    if left > right do return 0
    index := (left * MAX_BOXES + right) * (MAX_BOXES + 1) + carry
    if memo[index] >= 0 do return memo[index]
    attached := int(counts[left]) + carry
    best := i64(attached * attached) + solve_boxes(left + 1, right, 0, colors, counts, memo)
    for later := left + 1; later <= right; later += 1 {
        if colors[later] == colors[left] {
            joined := solve_boxes(left + 1, later - 1, 0, colors, counts, memo)
                + solve_boxes(later, right, attached, colors, counts, memo)
            if joined > best do best = joined
        }
    }
    memo[index] = best
    return best
}

@(export)
remove_boxes :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if values[0] < 0 || values[0] > MAX_BOXES do return -1
    n := int(values[0])
    if length != c.size_t(n + 1) do return -1
    colors: [MAX_BOXES]i64
    counts: [MAX_BOXES]i64
    groups := 0
    for index := 0; index < n; index += 1 {
        color := values[index + 1]
        if color < 0 || color > 7 do return -1
        if groups > 0 && colors[groups - 1] == color {
            counts[groups - 1] += 1
        } else {
            colors[groups] = color
            counts[groups] = 1
            groups += 1
        }
    }
    if groups == 0 do return 0
    memo: [MAX_MEMO]i64
    for index := 0; index < MAX_MEMO; index += 1 { memo[index] = -1 }
    return solve_boxes(0, groups - 1, 0, &colors[0], &counts[0], &memo[0])
}
