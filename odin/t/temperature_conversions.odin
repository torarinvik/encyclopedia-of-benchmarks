package temperature_conversions

import "core:c"

@(export)
temperature_conversions :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 || length > 3 do return -1e300
    operation, micro := values[0], values[1]
    if micro < -1_000_000_000_000 || micro > 1_000_000_000_000 do return -1e300
    switch operation {
    case 0:
        if micro % 5_000_000 != 0 do return -1e300
        return f64(9 * (micro / 5_000_000) + 32)
    case 1:
        if (micro - 32_000_000) % 9_000_000 != 0 do return -1e300
        return f64(5 * ((micro - 32_000_000) / 9_000_000))
    case 2:
        if micro % 1_000_000 != 0 do return -1e300
        return f64(micro / 1_000_000) + 273.15
    case 3:
        if (micro - 273_150_000) % 1_000_000 != 0 do return -1e300
        return f64((micro - 273_150_000) / 1_000_000)
    case 4:
        if (micro - 273_150_000) % 5_000_000 != 0 do return -1e300
        return f64(9 * ((micro - 273_150_000) / 5_000_000) + 32)
    }
    return -1e300
}
