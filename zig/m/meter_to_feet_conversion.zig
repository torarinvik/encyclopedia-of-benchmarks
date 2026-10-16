export fn meter_to_feet_conversion(v: [*]const i64, n: usize) f64 {
    if (n != 2) return -1.0e300;
    const op=v[0]; const units=v[1];
    if ((op != 0 and op != 1) or units < -1_000_000_000 or units > 1_000_000_000) return -1.0e300;
    const value=@as(f64,@floatFromInt(units))/1000.0;
    if (op == 0) return value*0.3048;
    return value/0.3048;
}
