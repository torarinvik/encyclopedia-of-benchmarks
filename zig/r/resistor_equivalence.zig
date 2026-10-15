/// Series and parallel resistor equivalents.
export fn resistor_equivalence(values: [*]const i64, length: usize) f64 {
    if (length < 2 or length > 33) return -1.0e300;
    const operation = values[0];
    if (operation != 0 and operation != 1) return -1.0e300;
    var accumulated: f64 = 0.0;
    var index: usize = 1;
    while (index < length) : (index += 1) {
        const resistor = values[index];
        if ((operation == 0 and resistor < 1) or (operation == 1 and resistor < 0) or resistor > 1000)
            return -1.0e300;
        if (operation == 0) {
            accumulated += 1.0 / @as(f64, @floatFromInt(resistor));
        } else {
            accumulated += @as(f64, @floatFromInt(resistor));
        }
    }
    if (operation == 0) return 1.0 / accumulated;
    return accumulated;
}
