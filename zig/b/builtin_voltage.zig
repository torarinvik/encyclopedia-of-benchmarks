/// PN junction built-in voltage over bounded integer concentrations.
export fn builtin_voltage(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const donor = values[0];
    const acceptor = values[1];
    const intrinsic = values[2];
    if (donor < 1 or donor > 1000 or acceptor < 1 or acceptor > 1000 or intrinsic < 1 or intrinsic > 1000 or
        donor <= intrinsic or acceptor <= intrinsic) return -1.0e300;
    const ratio = (@as(f64, @floatFromInt(donor)) * @as(f64, @floatFromInt(acceptor))) /
        (@as(f64, @floatFromInt(intrinsic)) * @as(f64, @floatFromInt(intrinsic)));
    return 1.380649e-23 * 300.0 * @log(ratio) / 1.602176634e-19;
}
