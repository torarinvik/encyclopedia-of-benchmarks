package pseudo_inverse

import "core:c"
import "core:math"

@(export)
pseudo_inverse :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > 7 do return -1
    for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
    if math.trunc(input[0]) != input[0] || input[0] < 1 || input[0] > 4 || input[1] != 1 do return -1
    rows := int(input[0])
    if input_length != c.size_t(2+rows) do return -1
    column: [4]f64
    squared_norm: f64 = 0
    for i in 0..<rows {
        value := input[2+i]
        if math.trunc(value) != value || value < -4 || value > 4 do return -1
        column[i] = value
        squared_norm += value*value
    }
    staged: [6]f64
    staged[0], staged[1] = 1, f64(rows)
    if math.sqrt_f64(squared_norm) < 1e-4 {
        for i in 0..<rows { staged[2+i] = 0 }
    } else {
        for i in 0..<rows { staged[2+i] = column[i]/squared_norm }
    }
    output_size := rows+2
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
