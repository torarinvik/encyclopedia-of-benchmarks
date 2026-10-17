module temperature_conversions

const max_abs_temperature_micro = i64(1_000_000_000_000)

@[export: 'temperature_conversions']
pub fn temperature_conversions(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 2 || length > 3 { return -1e300 }
    unsafe {
        operation := values[0]
        micro := values[1]
        if micro < -max_abs_temperature_micro || micro > max_abs_temperature_micro { return -1e300 }
        match operation {
            0 {
                if micro % 5_000_000 != 0 { return -1e300 }
                return f64(9 * (micro / 5_000_000) + 32)
            }
            1 {
                if (micro - 32_000_000) % 9_000_000 != 0 { return -1e300 }
                return f64(5 * ((micro - 32_000_000) / 9_000_000))
            }
            2 {
                if micro % 1_000_000 != 0 { return -1e300 }
                return f64(micro / 1_000_000) + 273.15
            }
            3 {
                if (micro - 273_150_000) % 1_000_000 != 0 { return -1e300 }
                return f64((micro - 273_150_000) / 1_000_000)
            }
            4 {
                if (micro - 273_150_000) % 5_000_000 != 0 { return -1e300 }
                return f64(9 * ((micro - 273_150_000) / 5_000_000) + 32)
            }
            else { return -1e300 }
        }
    }
}
