module present_value;
extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;
fn double round_two_python(double value) {
    if (value == 0.0) return value;
    bool negative = value < 0.0;
    double normalized = negative ? -value : value;
    long exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent++; }
    while (normalized < 0.5) { normalized *= 2.0; exponent--; }
    ulong significand = (ulong)(normalized * 9007199254740992.0);
    ulong numerator = significand * 100;
    long shift = 53 - exponent;
    ulong cents = 0;
    if (shift < 0) cents = numerator << (uint)(-shift);
    else if (shift == 0) cents = numerator;
    else if (shift < 64) {
        ulong denominator = ulong(1) << (uint)shift;
        cents = numerator >> (uint)shift;
        ulong remainder = numerator & (denominator - 1);
        ulong half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) cents++;
    }
    double rounded = (double)cents / 100.0;
    return negative ? -rounded : rounded;
}
fn double present_value(long* values, usz length) @export("present_value") {
    if (values == null || length < 3 || length > 10) return INVALID_RESULT;
    long count_value = values[0];
    long rate_ppm = values[1];
    if (count_value < 1 || count_value > 8 || length != 2 + (usz)count_value || (rate_ppm != 0 && rate_ppm != 1000000)) return INVALID_RESULT;
    usz count = (usz)count_value;
    for (usz i = 0; i < count; i++) if (values[i + 2] < -1000000 || values[i + 2] > 1000000 || values[i + 2] % 125 != 0) return INVALID_RESULT;
    double rate = (double)rate_ppm / 1000000.0;
    double total = 0.0;
    for (usz i = 0; i < count; i++) {
        double flow = (double)values[i + 2] / 1000.0;
        total += flow / pow(1.0 + rate, (double)i);
    }
    return round_two_python(total);
}
