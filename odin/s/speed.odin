package speed

import "core:c"

INVALID_RESULT :: -1.0e300
MAX_SPEED_MICRO :: i64(1_000_000_000_000_000)
MAX_ROUNDED_MILLI :: 9_007_199_254_740_992.0
TO_KMH :: [7]f64{1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1_079_252_848.8}
FROM_KMH :: [7]f64{1.0, 0.277777778, 0.621371192, 0.539956803,
                   0.911344415, 0.000816164, 9.265669311e-10}

round_three_away :: proc "contextless" (scaled: f64) -> f64 {
    if scaled == 0.0 do return scaled / 1000.0
    negative := scaled < 0.0
    magnitude := if negative do -scaled else scaled
    rounded_milli := u64(magnitude)
    if magnitude - f64(rounded_milli) >= 0.5 { rounded_milli += 1 }
    rounded := f64(rounded_milli) / 1000.0
    if negative do return -rounded
    return rounded
}

@(export)
speed :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 3 do return INVALID_RESULT
    speed_micro, from_unit, to_unit := values[0], values[1], values[2]
    if speed_micro < -MAX_SPEED_MICRO || speed_micro > MAX_SPEED_MICRO ||
        from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6 do return INVALID_RESULT
    speed_value := f64(speed_micro) / 1_000_000.0
    kmh := speed_value * TO_KMH[int(from_unit)]
    result := kmh * FROM_KMH[int(to_unit)]
    scaled := result * 1000.0
    if scaled > MAX_ROUNDED_MILLI || scaled < -MAX_ROUNDED_MILLI do return INVALID_RESULT
    return round_three_away(scaled)
}
