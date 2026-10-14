package pascal_triangle

import "core:c"

MAX_ROWS :: 30
HASH_MOD :: i64(1_000_000_007)

@(export)
pascal_triangle_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length != 1 do return -1
    row_count_value := values[0]
    if row_count_value < 0 || row_count_value > MAX_ROWS do return -1
    row_count := int(row_count_value)
    row: [MAX_ROWS]i64
    row[0] = 1
    hash: i64 = 0
    for row_index := 0; row_index < row_count; row_index += 1 {
        column := row_index
        for column > 0 {
            row[column] += row[column - 1]
            column -= 1
        }
        for col := 0; col <= row_index; col += 1 {
            hash = (hash * 31 + row[col] % HASH_MOD) % HASH_MOD
        }
    }
    return hash
}
