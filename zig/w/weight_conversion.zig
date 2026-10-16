fn destination_factor(code: f64) f64 {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 1000.0;
    if (code == 2.0) return 1000000.0;
    if (code == 3.0) return 0.001;
    if (code == 4.0) return 0.0009842073;
    if (code == 5.0) return 0.0011023122;
    if (code == 6.0) return 2.2046244202;
    if (code == 7.0) return 0.1574731728;
    if (code == 8.0) return 35.273990723;
    if (code == 9.0) return 5000.0;
    if (code == 10.0) return 6.022136652e26;
    return 0.0;
}

fn source_factor(code: f64) f64 {
    if (code == 0.0) return 1.0;
    if (code == 1.0) return 0.001;
    if (code == 2.0) return 0.000001;
    if (code == 3.0) return 1000.0;
    if (code == 4.0) return 1016.04608;
    if (code == 5.0) return 907.184;
    if (code == 6.0) return 0.453592;
    if (code == 7.0) return 6.35029;
    if (code == 8.0) return 0.0283495;
    if (code == 9.0) return 0.0002;
    if (code == 10.0) return 1.660540199e-27;
    return 0.0;
}

/// Convert weight using Python's source factor charts and operation order.
export fn weight_conversion(value: f64, from_code: f64, to_code: f64) f64 {
    if (std.math.isNan(value) or std.math.isInf(value) or value < -1_000_000.0 or value > 1_000_000.0) return -1e300;
    const destination = destination_factor(to_code);
    const source = source_factor(from_code);
    if (destination == 0.0 or source == 0.0) return -1e300;
    const scaled = value * destination;
    return scaled * source;
}
