/// Convert the pinned Rust weight units through kilograms, in source order.
const weight_factors = [_]f64{
    1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
    1016.0469088, 907.18474, 50.80234544, 12.70058636,
    6.35029318, 0.45359237, 0.028349523125, 0.0017718451953125, 0.00006479891,
    0.3732417216, 0.0311034768, 0.00155517384, 0.0002, 1.66053906660e-27,
};

fn toKilogramFactor(code: f64) f64 {
    if (code < 0.0 or code > 22.0 or @trunc(code) != code) return 0.0;
    return weight_factors[@intFromFloat(code)];
}

export fn weight(value: f64, from_code: f64, to_code: f64) f64 {
    if (value != value or value < -1_000_000.0 or value > 1_000_000.0) return -1e300;
    const from_factor = toKilogramFactor(from_code);
    const to_factor = toKilogramFactor(to_code);
    if (from_factor == 0.0 or to_factor == 0.0) return -1e300;
    const kilograms = value * from_factor;
    return kilograms / to_factor;
}
