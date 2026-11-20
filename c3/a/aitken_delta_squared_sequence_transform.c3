module aitken_delta_squared_sequence_transform;

const long MAX_TERMS = 64;
const usz MAX_WORDS = 66;
const long VALUE_LIMIT = 1000000;

fn ulong aitken_gcd(ulong left, ulong right) {
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn void aitken_store_i64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uchar)(bits >> (8 * byte));
}

fn long aitken_delta_squared_sequence_transform(long* values, usz length,
        uchar* output, usz output_capacity) @export("aitken_delta_squared_sequence_transform") {
    if (values == null || length < 3 || length > MAX_WORDS) return -1;
    long n_value = values[0];
    if (n_value < 2 || n_value > MAX_TERMS || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    for (usz i = 0; i < n; i++)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    usz output_length = 16 * (n - 2);
    if (output == null || output_capacity < output_length) return -2;

    for (usz i = 0; i + 2 < n; i++) {
        long first = values[i + 1];
        long middle = values[i + 2];
        long last = values[i + 3];
        long numerator = first * last - middle * middle;
        long denominator = first - 2 * middle + last;
        if (denominator == 0) {
            if (first == middle && middle == last) {
                numerator = first;
                denominator = 1;
            } else {
                numerator = 0;
            }
        } else {
            if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
            ulong magnitude = numerator < 0 ? (ulong)(-numerator) : (ulong)numerator;
            ulong divisor = aitken_gcd(magnitude, (ulong)denominator);
            numerator /= (long)divisor;
            denominator /= (long)divisor;
        }
        usz offset = i * 16;
        aitken_store_i64(output, offset, numerator);
        aitken_store_i64(output, offset + 8, denominator);
    }
    return (long)output_length;
}
