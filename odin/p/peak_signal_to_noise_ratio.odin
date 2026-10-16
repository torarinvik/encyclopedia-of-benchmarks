package peak_signal_to_noise_ratio

import "core:math"

@(export)
peak_signal_to_noise_ratio :: proc "c" (v: [^]i64, n: u64) -> f64 {
    if v == nil || n < 3 || n > 129 || v[0] < 1 || v[0] > 64 || n != 1 + 2 * u64(v[0]) do return -1e300
    count := u64(v[0])
    sum: f64 = 0
    for i: u64 = 0; i < count; i += 1 {
        a, b := v[i + 1], v[i + 1 + count]
        if a < 0 || a > 255 || b < 0 || b > 255 do return -1e300
        if a - b < -15 || a - b > 15 do return -1e300
        d := f64(a) - f64(b)
        sum += d * d
    }
    mse := sum / f64(count)
    if mse == 0 do return -1e300
    return 20 * math.log10(255 / math.sqrt(mse))
}
