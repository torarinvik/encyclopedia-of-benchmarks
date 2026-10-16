package heaps

import "core:c"

MAX_N :: 7

emit_row :: proc "contextless" (items: [^]u8, n: int, output: [^]u8, rows: ^int) {
    offset := rows^ * n
    for index := 0; index < n; index += 1 { output[offset + index] = items[index] }
    rows^ += 1
}

generate :: proc "contextless" (items: [^]u8, n, size: int, output: [^]u8, rows: ^int) {
    if size == 1 {
        emit_row(items, n, output, rows)
        return
    }
    for index := 0; index < size; index += 1 {
        generate(items, n, size - 1, output, rows)
        swap_index := index
        if size % 2 == 0 do swap_index = 0
        temporary := items[swap_index]
        items[swap_index] = items[size - 1]
        items[size - 1] = temporary
    }
}

@(export)
heaps :: proc "c" (values: [^]i64, length: c.size_t,
                    output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length != 1 || values[0] < 0 || values[0] > MAX_N do return -1
    n := int(values[0])
    if n == 0 do return 0
    row_count := 1
    for factor := 2; factor <= n; factor += 1 { row_count *= factor }
    required := row_count * n
    if output == nil || capacity < c.size_t(required) do return -2
    items: [MAX_N]u8
    for index := 0; index < n; index += 1 { items[index] = u8(49 + index) }
    rows := 0
    generate(&items[0], n, n, output, &rows)
    return i64(rows)
}
