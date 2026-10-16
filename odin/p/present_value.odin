package present_value

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

round_two_python :: proc "contextless" (value: f64) -> f64 {
    if value == 0.0 do return value
    negative := value < 0.0
    normalized := if negative do -value else value
    exponent := 0
    for normalized >= 1.0 { normalized *= 0.5; exponent += 1 }
    for normalized < 0.5 { normalized *= 2.0; exponent -= 1 }
    significand := u64(normalized * 9_007_199_254_740_992.0)
    numerator := significand * 100
    shift := 53 - exponent
    cents: u64 = 0
    if shift < 0 { cents = numerator << u32(-shift) }
    else if shift == 0 { cents = numerator }
    else if shift < 64 {
        denominator := u64(1) << u32(shift)
        cents = numerator >> u32(shift)
        remainder := numerator & (denominator - 1)
        half := denominator >> 1
        if remainder > half || (remainder == half && cents & 1 != 0) { cents += 1 }
    }
    rounded := f64(cents) / 100.0
    if negative do return -rounded
    return rounded
}

@(export)
present_value :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 3 || length > 10 do return INVALID_RESULT
    count_value := values[0]
    rate_ppm := values[1]
    if count_value < 1 || count_value > 8 || length != c.size_t(2 + count_value) || (rate_ppm != 0 && rate_ppm != 1_000_000) do return INVALID_RESULT
    count := int(count_value)
    for i := 0; i < count; i += 1 {
        flow := values[i + 2]
        if flow < -1_000_000 || flow > 1_000_000 || flow % 125 != 0 do return INVALID_RESULT
    }
    rate := f64(rate_ppm) / 1_000_000.0
    total: f64 = 0.0
    for i := 0; i < count; i += 1 {
        flow := f64(values[i + 2]) / 1000.0
        total += flow / math.pow_f64(1.0 + rate, f64(i))
    }
    return round_two_python(total)
}
