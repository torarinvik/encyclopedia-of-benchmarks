module euler_alternating_series_transform;

const long MAX_TERMS = 16;
const usz MAX_WORDS = 18;
const long VALUE_LIMIT = 1000000;
const usz OUTPUT_BYTES = 16;

fn ulong euler_gcd(ulong left, ulong right) {
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn void euler_store_i64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uchar)(bits >> (8 * byte));
}

fn long euler_alternating_series_transform(long* values, usz length,
        uchar* output, usz output_capacity) @export("euler_alternating_series_transform") {
    if (values == null || length < 2 || length > MAX_WORDS) return -1;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_TERMS || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    for (usz index = 0; index < n; index++)
        if (values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    long numerator = 0;
    for (usz order = 0; order < n; order++) {
        long difference = 0;
        long coefficient = 1;
        for (usz index = 0; index <= order; index++) {
            long term = values[order - index + 1];
            if (index % 2 == 0) difference += coefficient * term;
            else difference -= coefficient * term;
            if (index < order) coefficient = coefficient * (long)(order - index) / (long)(index + 1);
        }
        long weight = (long)1 << (n - order - 1);
        long weighted = difference * weight;
        if (order % 2 == 0) numerator += weighted;
        else numerator -= weighted;
    }

    long denominator = (long)1 << n;
    ulong magnitude = numerator < 0 ? (ulong)(-numerator) : (ulong)numerator;
    ulong divisor = euler_gcd(magnitude, (ulong)denominator);
    numerator /= (long)divisor;
    denominator /= (long)divisor;
    euler_store_i64(output, 0, numerator);
    euler_store_i64(output, 8, denominator);
    return (long)OUTPUT_BYTES;
}
