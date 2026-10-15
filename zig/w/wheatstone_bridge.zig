/// Solve the unknown resistance in a balanced Wheatstone bridge.
export fn wheatstone_bridge(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const resistance_1 = values[0];
    const resistance_2 = values[1];
    const resistance_3 = values[2];
    if (resistance_1 < 1 or resistance_1 > 1_000_000 or
        resistance_2 < 1 or resistance_2 > 1_000_000 or
        resistance_3 < 1 or resistance_3 > 1_000_000) return -1.0e300;
    return (@as(f64, @floatFromInt(resistance_2)) / @as(f64, @floatFromInt(resistance_1))) *
           @as(f64, @floatFromInt(resistance_3));
}
