package recursive_linear_search

import "core:c"

MAX_N :: 64
I32_MIN :: -2147483648
I32_MAX :: 2147483647

search_recursive :: proc(items: ^[MAX_N]i32, left, right: int, target: i32) -> int {
    if left > right do return -1
    if items[left] == target do return left
    if items[right] == target do return right
    return search_recursive(items, left + 1, right - 1, target)
}

@(export, link_name="recursive_linear_search")
recursive_linear_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(MAX_N + 2) do return -1
    if input[0] < 2 || input[0] > MAX_N || length != c.size_t(input[0] + 2) do return -1
    if input[1] < I32_MIN || input[1] > I32_MAX do return -1
    n := int(input[0])
    items: [MAX_N]i32
    for i := 0; i < n; i += 1 {
        if input[i + 2] < I32_MIN || input[i + 2] > I32_MAX do return -1
        items[i] = i32(input[i + 2])
        for j := 0; j < i; j += 1 { if items[j] == items[i] do return -1 }
    }
    return i64(search_recursive(&items, 0, n - 1, i32(input[1])))
}
