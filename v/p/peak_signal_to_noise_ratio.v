module peak_signal_to_noise_ratio

import math

@[export: 'peak_signal_to_noise_ratio']
pub fn peak_signal_to_noise_ratio(v &i64, n usize) f64 {
    if isnil(v) || n < 3 || n > 129 || v[0] < 1 || v[0] > 64 || n != 1 + 2 * usize(v[0]) { return -1e300 }
    count := usize(v[0])
    mut sum := 0.0
    for i in 0 .. count {
        a := v[i + 1]
        b := v[i + 1 + count]
        if a < 0 || a > 255 || b < 0 || b > 255 { return -1e300 }
        if a - b < -15 || a - b > 15 { return -1e300 }
        d := f64(a) - f64(b)
        sum += d * d
    }
    mse := sum / f64(count)
    if mse == 0.0 { return -1e300 }
    return 20.0 * math.log10(255.0 / math.sqrt(mse))
}
