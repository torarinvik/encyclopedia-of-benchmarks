package cusum_detector

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := transmute(u64)value
    for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}
@(export)
cusum_detector :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 do return -1
    if input[0] < 0 || input[0] > 128 do return -1
    n := usize(input[0]); if length != c.size_t(n+5) do return -1
    target, sigma, allowance, threshold := input[1], input[2], input[3], input[4]
    if target < -1000 || target > 1000 || sigma < 1 || sigma > 1000 || allowance < 0 || allowance > 1000 || threshold < 1 || threshold > 1000 do return -1
    for i: usize = 0; i < n; i += 1 { if input[5+i] < -1000 || input[5+i] > 1000 do return -1 }
    if capacity < n*8 || (n > 0 && output == nil) do return -2
    upper, lower: f64 = 0.0, 0.0
    for i: usize = 0; i < n; i += 1 {
        z := (f64(input[5+i])-f64(target))/f64(sigma)
        upper += z-f64(allowance); if upper < 0 do upper = 0
        lower += -z-f64(allowance); if lower < 0 do lower = 0
        signal: i64 = 0
        if upper > f64(threshold) do signal = 1
        else if lower > f64(threshold) do signal = -1
        if signal != 0 { upper = 0; lower = 0 }
        put_i64_le(output,i*8,signal)
    }
    return i64(n*8)
}
