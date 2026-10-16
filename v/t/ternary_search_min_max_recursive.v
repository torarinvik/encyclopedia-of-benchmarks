module main

const invalid_result = -1.0e300

fn minimum_function(x f32) f32 { return x * x - 2.0 * x + 3.0 }
fn maximum_function(x f32) f32 { return -x * x - 2.0 * x + 3.0 }
fn absolute_f32(x f32) f32 { return if x < 0.0 { -x } else { x } }

fn ternary_min(start f32, finish f32, precision f32) f32 {
    width := finish - start
    if absolute_f32(width) >= precision {
        mid1 := start + width / 3.0
        mid2 := finish - width / 3.0
        r1 := minimum_function(mid1)
        r2 := minimum_function(mid2)
        if r1 < r2 { return ternary_min(start, mid2, precision) }
        if r1 > r2 { return ternary_min(mid1, finish, precision) }
        return ternary_min(mid1, mid2, precision)
    }
    return minimum_function(start)
}

fn ternary_max(start f32, finish f32, precision f32) f32 {
    width := finish - start
    if absolute_f32(width) >= precision {
        mid1 := start + width / 3.0
        mid2 := finish - width / 3.0
        r1 := maximum_function(mid1)
        r2 := maximum_function(mid2)
        if r1 < r2 { return ternary_max(mid1, finish, precision) }
        if r1 > r2 { return ternary_max(start, mid2, precision) }
        return ternary_max(mid1, mid2, precision)
    }
    return maximum_function(start)
}

@[export: 'ternary_search_min_max_recursive']
pub fn ternary_search_min_max_recursive(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 4 { return invalid_result }
    mode := unsafe { values[0] }
    start_milli := unsafe { values[1] }
    end_milli := unsafe { values[2] }
    precision_milli := unsafe { values[3] }
    center_milli := if mode == 0 { i64(1000) } else if mode == 1 { i64(-1000) } else { i64(0) }
    if mode < 0 || mode > 1 || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || precision_milli < 1 || precision_milli > 8 { return invalid_result }
    start := f32(start_milli) / 1000.0
    finish := f32(end_milli) / 1000.0
    precision := f32(precision_milli) / 1000.0
    if mode == 0 { return f64(ternary_min(start, finish, precision)) }
    return f64(ternary_max(start, finish, precision))
}
