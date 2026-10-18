module simplify_fraction;

const long MAX_ABS_COMPONENT = 1000000L;
const usz OUTPUT_BYTES = 16;

fn ulong magnitude(long value) { return value < 0 ? (ulong)(-value) : (ulong)value; }
fn ulong gcd_positive(ulong a, ulong b) {
    while (b != 0) { ulong remainder = a % b; a = b; b = remainder; }
    return a;
}
fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long simplify_fraction(long* input, usz input_length, char* output, usz capacity)
    @export("simplify_fraction") {
    if (input == null || input_length != 2) return -1L;
    long numerator = input[0], denominator = input[1];
    if (numerator < -MAX_ABS_COMPONENT || numerator > MAX_ABS_COMPONENT ||
        denominator < -MAX_ABS_COMPONENT || denominator > MAX_ABS_COMPONENT || denominator == 0) return -1L;
    ulong divisor = gcd_positive(magnitude(numerator), magnitude(denominator));
    long reduced_numerator = numerator / (long)divisor;
    long reduced_denominator = denominator / (long)divisor;
    char[OUTPUT_BYTES] staged = zeroed;
    put_i64_le(&staged[0], 0, reduced_numerator);
    put_i64_le(&staged[0], 8, reduced_denominator);
    if (output == null || capacity < OUTPUT_BYTES) return -2L;
    for (usz i = 0; i < OUTPUT_BYTES; i++) output[i] = staged[i];
    return (long)OUTPUT_BYTES;
}
