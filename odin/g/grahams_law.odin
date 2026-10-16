package grahams_law

import "core:c"
import "core:math"

rounded_six :: proc(value: f64) -> f64 {
    if !(value >= 0.0 && value <= 1.0e6) do return -1.0e300
    scaled := value * 1_000_000.0
    lower := math.floor_f64(scaled)
    fraction := scaled - lower
    if fraction >= 0.499 && fraction <= 0.501 do return -1.0e300
    if fraction > 0.5 do lower += 1.0
    return lower / 1_000_000.0
}

decode_positive :: proc(values: [^]i64, index: int) -> f64 {
    result := transmute(f64)values[index]
    if !(result >= 1.0e-6 && result <= 1.0e6) do return 0.0
    return result
}

@(export)
grahams_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 3 || length > 4 || values[0] < 0 || values[0] > 4 do return -1.0e300
    operation := values[0]
    if (operation == 0 && length != 3) || (operation != 0 && length != 4) do return -1.0e300
    first := decode_positive(values, 1)
    second := decode_positive(values, 2)
    if first == 0.0 || second == 0.0 do return -1.0e300
    result: f64
    if operation == 0 do result = math.sqrt_f64(second / first)
    else {
        third := decode_positive(values, 3)
        if third == 0.0 do return -1.0e300
        if operation == 1 do result = first * math.sqrt_f64(third / second)
        else if operation == 2 do result = first / math.sqrt_f64(third / second)
        else if operation == 3 do result = first / math.pow_f64(second / third, 2.0)
        else result = math.pow_f64(second / third, 2.0) / first
    }
    return rounded_six(result)
}
