module data_transformations;

const usz MAX_SAMPLE_COUNT = 128;

fn double round_three_decimals(double value) {
    ulong bits = @bitcast(ulong, value);
    bool negative = (bits >> 63) != 0;
    ulong exponent = (bits >> 52) & 2047;
    ulong fraction = bits & ((1ul << 52) - 1);
    ulong significand = exponent == 0 ? fraction : fraction | (1ul << 52);
    long exponent2 = exponent == 0 ? -1074 : (long)exponent - 1023 - 52;
    ulong scaled = significand * 1000;
    ulong rounded = 0;
    if (exponent2 >= 0) {
        rounded = scaled << (usz)exponent2;
    } else {
        usz shift = (usz)(-exponent2);
        if (shift < 64) {
            rounded = scaled >> shift;
            if (shift != 0) {
                ulong remainder = scaled & ((1ul << shift) - 1);
                ulong half = 1ul << (shift - 1);
                if (remainder > half || (remainder == half && (rounded & 1) != 0)) rounded++;
            }
        }
    }
    double result = (double)rounded / 1000.0;
    return negative ? -result : result;
}

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long data_transformations(long* values, usz length, char* output, usz capacity)
    @export("data_transformations") {
    if (values == null || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    long mode = values[0], count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > (long)MAX_SAMPLE_COUNT ||
        length != (usz)count_arg + 2) return -1;
    usz count = (usz)count_arg;
    long minimum = values[2], maximum = values[2], sum = 0, sum_squares = 0;
    for (usz index = 0; index < count; index++) {
        long value = values[index + 2];
        if (value < -100000 || value > 100000) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += value;
        sum_squares += value * value;
    }
    if (minimum == maximum) return -1;
    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    if (mode == 0) {
        double span = (double)(maximum - minimum);
        for (usz index = 0; index < count; index++) {
            double normalized = (double)(values[index + 2] - minimum) / span;
            put_f64_le(round_three_decimals(normalized), output, index * 8);
        }
    } else {
        double average = (double)sum / (double)count;
        long variance_numerator = (long)count * sum_squares - sum * sum;
        double variance_denominator = (double)(count * (count - 1));
        extern fn double sqrt(double value);
        double deviation = sqrt((double)variance_numerator / variance_denominator);
        for (usz index = 0; index < count; index++) {
            double standardized = ((double)values[index + 2] - average) / deviation;
            put_f64_le(round_three_decimals(standardized), output, index * 8);
        }
    }
    return (long)output_bytes;
}
