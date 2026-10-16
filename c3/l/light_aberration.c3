module light_aberration;

extern fn double sqrt(double value);
extern fn double tan(double value);
extern fn double atan(double value);
extern fn double floor(double value);

const double INVALID_RESULT = -1.0e300;

fn double round_five_even(double value) {
    double scaled = value * 100000.0;
    double fraction = scaled - floor(scaled);
    double distance = fraction - 0.5;
    if (distance < 0.0) distance = -distance;
    if (distance <= 1.0e-7) return INVALID_RESULT;
    if (value == 0.0) return value;
    bool negative = value < 0.0;
    double normalized = if negative then -value else value;
    int exponent = 0;
    while (normalized < 1.0) { normalized *= 2.0; exponent--; }
    while (normalized >= 2.0) { normalized *= 0.5; exponent++; }
    ulong mantissa = (ulong)(normalized * 4503599627370496.0);
    int shift = 52 - exponent;
    if (shift > 70) return if negative then -0.0 else 0.0;
    ulong low_product = (mantissa & 0xffffffff) * 100000;
    ulong high_product = (mantissa >> 32) * 100000;
    ulong shifted_high = high_product << 32;
    ulong low = low_product + shifted_high;
    ulong carry = 0;
    if (low < low_product) carry = 1;
    ulong high = (high_product >> 32) + carry;
    ulong quotient = if shift < 64 then (low >> shift) | (high << (64 - shift)) else high >> (shift - 64);
    ulong half_bit = if shift - 1 < 64 then (low >> (shift - 1)) & 1 else (high >> (shift - 65)) & 1;
    bool lower_bits = if shift - 1 < 64 then (low & ((1ul << (shift - 1)) - 1)) != 0
        else low != 0 || (high & ((1ul << (shift - 65)) - 1)) != 0;
    ulong increment = 0;
    if (half_bit != 0 && (lower_bits || (quotient & 1) != 0)) increment = 1;
    ulong rounded = quotient + increment;
    double result = (double)rounded / 100000.0;
    return if negative then -result else result;
}

fn double light_aberration(long* values, usz length) @export("light_aberration") {
    if (values == null || length != 2) return INVALID_RESULT;
    long theta_code = values[0];
    long beta_code = values[1];
    if (theta_code < -3141592 || theta_code > 3141592 || beta_code < 0 || beta_code > 999999) return INVALID_RESULT;
    double theta = (double)theta_code / 1000000.0;
    double beta = (double)beta_code / 1000000.0;
    double factor = sqrt((1.0 - beta) / (1.0 + beta));
    double angle = 2.0 * atan(factor * tan(theta / 2.0));
    return round_five_even(angle);
}
