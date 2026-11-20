package entringer_number

import "core:c"

@(export)
entringer_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    n, target := values[0], values[1]
    if n < 0 || n > 12 || target < 0 || target > n do return -1
    n_int, target_int := int(n), int(target)
    previous: [13]i64 = {}
    current: [13]i64 = {}
    previous[0] = 1
    for row := 1; row <= n_int; row += 1 {
        current[0] = 0
        for col := 1; col <= row; col += 1 {
            current[col] = current[col-1] + previous[row-col]
        }
        for i := 0; i < 13; i += 1 {
            previous[i] = current[i]
            current[i] = 0
        }
    }
    return previous[target_int]
}
