const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846264338327950288;

export fn gaussian(values: [*]const i64, length: usize) f64 {
    if (length != 3) return INVALID_RESULT;
    const x = values[0];
    const mu = values[1];
    const sigma = values[2];
    if (x < -100 or x > 100 or mu < -100 or mu > 100 or sigma < 1 or sigma > 100) return INVALID_RESULT;
    const difference = x - mu;
    const sigma_squared = sigma * sigma;
    const normalization = 1.0 / @sqrt(2.0 * PI * @as(f64, @floatFromInt(sigma_squared)));
    const exponent = -@as(f64, @floatFromInt(difference * difference)) / @as(f64, @floatFromInt(2 * sigma_squared));
    return normalization * @exp(exponent);
}
