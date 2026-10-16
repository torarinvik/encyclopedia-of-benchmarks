const SCALE: i64 = 1_000_000;
const MAX_PRICE_MICRO: i64 = 1_000_000_000_000;
const MAX_TAX_RATE_MICRO: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

export fn price_plus_tax(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const price_micro = values[0];
    const tax_rate_micro = values[1];
    if (price_micro < 0 or price_micro > MAX_PRICE_MICRO
        or tax_rate_micro < 0 or tax_rate_micro > MAX_TAX_RATE_MICRO) return INVALID_RESULT;
    const price = @as(f64, @floatFromInt(price_micro)) / @as(f64, @floatFromInt(SCALE));
    const tax_rate = @as(f64, @floatFromInt(tax_rate_micro)) / @as(f64, @floatFromInt(SCALE));
    return price * (1.0 + tax_rate);
}
