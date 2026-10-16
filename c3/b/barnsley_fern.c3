module barnsley_fern;

const long MAX_ITERATIONS = 4096;
const long Q12_OFFSET = 10000000000;
const long Q6_DIVISOR = 1000000;

fn long round_div_even(long numerator, long denominator) {
    bool negative = numerator < 0;
    ulong magnitude = (ulong)(negative ? -numerator : numerator);
    ulong divisor = (ulong)denominator;
    ulong quotient = magnitude / divisor;
    ulong remainder = magnitude % divisor;
    if (remainder * 2 > divisor || (remainder * 2 == divisor && (quotient & 1) != 0)) quotient++;
    return negative ? -(long)quotient : (long)quotient;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long barnsley_fern(long* input, usz length, char* output, usz capacity) @export("barnsley_fern") {
    if (input == null || length < 1) return -1;
    long iteration_value = input[0];
    if (iteration_value < 1 || iteration_value > MAX_ITERATIONS || length != (usz)iteration_value) return -1;
    usz iterations = (usz)iteration_value;
    for (usz step = 1; step < iterations; step++) {
        if (input[step] < 0 || input[step] >= 10000) return -1;
    }
    usz output_length = iterations * 16;
    if (output == null || capacity < output_length) return -2;

    long x = 0;
    long y = 0;
    put_i64_le(output, 0, 0);
    put_i64_le(output, 8, 0);
    for (usz step = 1; step < iterations; step++) {
        long sample = input[step];
        long a = 0;
        long b = 0;
        long c = 0;
        long d = 0;
        long e = 0;
        long f = 0;
        if (sample < 100) { a = 0; b = 0; c = 0; d = 16; }
        else if (sample < 8600) { a = 85; b = 4; c = -4; d = 85; f = 160; }
        else if (sample < 9300) { a = 20; b = -26; c = 23; d = 22; f = 160; }
        else { a = -15; b = 28; c = 26; d = 24; f = 44; }
        long next_x = round_div_even(a * x + b * y, 100) + e * Q12_OFFSET;
        long next_y = round_div_even(c * x + d * y, 100) + f * Q12_OFFSET;
        x = next_x;
        y = next_y;
        put_i64_le(output, step * 16, round_div_even(x, Q6_DIVISOR));
        put_i64_le(output, step * 16 + 8, round_div_even(y, Q6_DIVISOR));
    }
    return (long)output_length;
}
