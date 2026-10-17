package sparse_matrix

import "core:c"

@(export)
sparse_matrix :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 4099 do return -1
    rows_value := values[0]
    columns_value := values[1]
    if rows_value < 1 || rows_value > 64 || columns_value < 1 || columns_value > 64 do return -1
    rows := int(rows_value)
    columns := int(columns_value)
    cells := rows * columns
    if length != c.size_t(2 + cells) do return -1
    zero_count: i64 = 0
    for index := 0; index < cells; index += 1 {
        value := values[2 + index]
        if value < -2_147_483_648 || value > 2_147_483_647 do return -1
        if value == 0 do zero_count += 1
    }
    if zero_count > i64(cells / 2) do return 1
    return 0
}
