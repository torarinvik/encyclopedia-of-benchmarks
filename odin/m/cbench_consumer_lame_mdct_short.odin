package cbench_consumer_lame_mdct_short

import "core:c"
import "core:math"

PI :: 3.14159265358979323846264338327950288
ENWINDOW_MAX :: 0.030526638

@(export)
cbench_consumer_lame_mdct_short :: proc "c" (input: [^]f64, input_length: c.size_t,
        output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > 19 do return -1
    for k := 0; k < int(input_length); k += 1 {
        value := input[k]
        if value != value || value < -32768.0 || value > 32768.0 do return -1
    }
    if input_length != c.size_t(18) do return -1
    coefficients: [36]f64
    scale := 4.0 / 12.0
    for i := 0; i < 3; i += 1 {
        w2 := math.cos(PI / 12.0 * (f64(i) + 0.5)) * ENWINDOW_MAX / 32768.0 * scale
        for m := 0; m < 6; m += 1 {
            coefficients[6*m+i] = w2 * math.cos((PI / 48.0) * f64(2*m+1) * f64(4*i+14))
            coefficients[6*m+i+3] = w2 * math.cos((PI / 48.0) * f64(2*m+1) * f64(4*i+38))
        }
    }
    staged: [18]f64
    for m := 5; m >= 0; m -= 1 {
        for l := 2; l >= 0; l -= 1 {
            base := 6*l
            total := coefficients[6*m] * input[base]
            for i := 1; i < 6; i += 1 { total += coefficients[6*m+i] * input[base+i] }
            staged[3*m+l] = total
        }
    }
    if output == nil || output_capacity < c.size_t(18) do return -2
    for i := 0; i < 18; i += 1 { output[i] = staged[i] }
    return 18
}
