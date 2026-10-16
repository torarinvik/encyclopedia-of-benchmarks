package ternary_search_min_max_recursive

import "core:c"

INVALID_RESULT :: f64(-1.0e300)

minimum_function :: proc(x: f32) -> f32 { return x * x - 2.0 * x + 3.0 }
maximum_function :: proc(x: f32) -> f32 { return -x * x - 2.0 * x + 3.0 }

absolute_f32 :: proc(x: f32) -> f32 { if x < 0 do return -x; return x }

ternary_min :: proc(start, finish, precision: f32) -> f32 {
    width := finish - start
    if absolute_f32(width) >= precision {
        mid1 := start + width / 3.0
        mid2 := finish - width / 3.0
        r1 := minimum_function(mid1)
        r2 := minimum_function(mid2)
        if r1 < r2 do return ternary_min(start, mid2, precision)
        if r1 > r2 do return ternary_min(mid1, finish, precision)
        return ternary_min(mid1, mid2, precision)
    }
    return minimum_function(start)
}

ternary_max :: proc(start, finish, precision: f32) -> f32 {
    width := finish - start
    if absolute_f32(width) >= precision {
        mid1 := start + width / 3.0
        mid2 := finish - width / 3.0
        r1 := maximum_function(mid1)
        r2 := maximum_function(mid2)
        if r1 < r2 do return ternary_max(mid1, finish, precision)
        if r1 > r2 do return ternary_max(start, mid2, precision)
        return ternary_max(mid1, mid2, precision)
    }
    return maximum_function(start)
}

@(export)
ternary_search_min_max_recursive :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 4 do return INVALID_RESULT
    mode, start_milli, end_milli, precision_milli := values[0], values[1], values[2], values[3]
    center_milli := i64(0)
    if mode == 0 do center_milli = 1000
    else if mode == 1 do center_milli = -1000
    if mode < 0 || mode > 1 || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || precision_milli < 1 || precision_milli > 8 do return INVALID_RESULT
    start := f32(start_milli) / 1000.0
    finish := f32(end_milli) / 1000.0
    precision := f32(precision_milli) / 1000.0
    if mode == 0 do return f64(ternary_min(start, finish, precision))
    return f64(ternary_max(start, finish, precision))
}
