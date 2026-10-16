package heaps_algorithm

import "core:c"

MAX_VALUES :: 6
BYTES_PER_VALUE :: 8

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

emit_row :: proc "contextless" (values: [^]i64, n: int, output: [^]u8, rows: ^int) {
    row_offset := rows^ * n * BYTES_PER_VALUE
    for index := 0; index < n; index += 1 {
        store_i64_le(output, row_offset + index * BYTES_PER_VALUE, values[index])
    }
    rows^ += 1
}

generate :: proc "contextless" (values: [^]i64, n, k: int, output: [^]u8, rows: ^int) {
    if k == 1 {
        emit_row(values, n, output, rows)
        return
    }
    generate(values, n, k - 1, output, rows)
    for index := 0; index < k - 1; index += 1 {
        swap_index := index
        if k % 2 != 0 do swap_index = 0
        temporary := values[swap_index]
        values[swap_index] = values[k - 1]
        values[k - 1] = temporary
        generate(values, n, k - 1, output, rows)
    }
}

@(export)
heaps_algorithm :: proc "c" (values: [^]i64, length: c.size_t,
                              output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > MAX_VALUES do return -1
    n := int(length)
    row_count := 1
    for factor := 2; factor <= n; factor += 1 { row_count *= factor }
    required := row_count * n * BYTES_PER_VALUE
    if output == nil || capacity < c.size_t(required) do return -2
    items: [MAX_VALUES]i64
    for index := 0; index < n; index += 1 { items[index] = values[index] }
    rows := 0
    generate(&items[0], n, n, output, &rows)
    return i64(rows)
}
