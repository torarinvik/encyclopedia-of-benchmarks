/// Estimate altitude from pressure using the pinned source formula.
export fn altitude_pressure(pressure: f64) f64 {
    if (pressure < 0.0 or pressure > 101325.0) return -1.0;
    if (pressure == 0.0) return 44330.0;
    const exponent = 1.0 / 5.5255;
    return 44330.0 * (1.0 - @exp(exponent * @log(pressure / 101325.0)));
}
