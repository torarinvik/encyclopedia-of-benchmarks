module speed

const invalid_result = -1.0e300
const max_speed_micro = i64(1_000_000_000_000_000)
const max_rounded_milli = 9_007_199_254_740_992.0

fn to_kmh_factor(unit i64) f64 {
    if unit == 0 { return 1.0 }
    if unit == 1 { return 3.6 }
    if unit == 2 { return 1.609344 }
    if unit == 3 { return 1.852 }
    if unit == 4 { return 1.09728 }
    if unit == 5 { return 1225.08 }
    return 1_079_252_848.8
}

fn from_kmh_factor(unit i64) f64 {
    if unit == 0 { return 1.0 }
    if unit == 1 { return 0.277777778 }
    if unit == 2 { return 0.621371192 }
    if unit == 3 { return 0.539956803 }
    if unit == 4 { return 0.911344415 }
    if unit == 5 { return 0.000816164 }
    return 9.265669311e-10
}

fn round_three_away(scaled f64) f64 {
    if scaled == 0.0 { return scaled / 1000.0 }
    negative := scaled < 0.0
    magnitude := if negative { -scaled } else { scaled }
    mut rounded_milli := u64(magnitude)
    if magnitude - f64(rounded_milli) >= 0.5 { rounded_milli++ }
    rounded := f64(rounded_milli) / 1000.0
    if negative { return -rounded }
    return rounded
}

@[export: 'speed']
pub fn speed(values &i64, length usize) f64 {
    if length != 3 { return invalid_result }
    unsafe {
        if values == nil { return invalid_result }
        speed_micro := values[0]
        from_unit := values[1]
        to_unit := values[2]
        if speed_micro < -max_speed_micro || speed_micro > max_speed_micro ||
            from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6 { return invalid_result }
        speed_value := f64(speed_micro) / 1_000_000.0
        kmh := speed_value * to_kmh_factor(from_unit)
        result := kmh * from_kmh_factor(to_unit)
        scaled := result * 1000.0
        if scaled > max_rounded_milli || scaled < -max_rounded_milli { return invalid_result }
        return round_three_away(scaled)
    }
}
