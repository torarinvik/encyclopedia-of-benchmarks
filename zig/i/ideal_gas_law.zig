/// Solve one ideal-gas-law variable using a portable operation selector.
export fn ideal_gas_law(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    const operation = values[0];
    const a = values[1];
    const b = values[2];
    const c = values[3];
    if (operation < 0 or operation > 3 or a < 0 or a > 1000 or b < 0 or b > 1000 or c < 0 or c > 1000)
        return -1.0e300;
    if (operation == 0 or operation == 1) {
        if (c == 0) return -1.0e300;
        return (@as(f64, @floatFromInt(a)) * @as(f64, @floatFromInt(b)) * 8.314462) / @as(f64, @floatFromInt(c));
    }
    if (a == 0) return -1.0e300;
    return (@as(f64, @floatFromInt(c)) * @as(f64, @floatFromInt(b))) /
        (@as(f64, @floatFromInt(a)) * 8.314462);
}
