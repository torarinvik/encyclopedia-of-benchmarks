module felzenszwalb_huttenlocher_1d_squared_distance_transform;

const usz MAX_SITES = 128;
const usz MAX_INPUT_WORDS = 130;

fn long floor_div(long numerator, long denominator) {
    long quotient = numerator / denominator;
    long remainder = numerator % denominator;
    if (remainder != 0 && numerator < 0) quotient -= 1;
    return quotient;
}

fn void store_i64_le(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    usz offset = word * 8;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long felzenszwalb_huttenlocher_1d_squared_distance_transform(
    long* input, usz length, char* output, usz output_capacity)
        @export("felzenszwalb_huttenlocher_1d_squared_distance_transform") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_SITES) return -1;
    usz n = (usz)n64;
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 1] < 0 || input[i + 1] > 1000000) return -1;
    if (output == null || output_capacity < n * 16) return -2;

    usz[MAX_SITES] sites = {0};
    long[MAX_SITES] starts = {0};
    usz top = 0;
    sites[0] = 0;
    starts[0] = -4611686018427387904;
    for (usz q = 1; q < n; q++) {
        for (;;) {
            usz p = sites[top];
            long numerator = input[q + 1] + (long)(q * q)
                - input[p + 1] - (long)(p * p);
            long denominator = (long)(2 * (q - p));
            long first = floor_div(numerator, denominator) + 1;
            if (top == 0 || first > starts[top]) {
                top += 1;
                sites[top] = q;
                starts[top] = first;
                break;
            }
            top -= 1;
        }
    }

    usz active = 0;
    for (usz x = 0; x < n; x++) {
        while (active < top && starts[active + 1] <= (long)x) active += 1;
        usz site = sites[active];
        long delta = (long)x - (long)site;
        long distance = delta * delta + input[site + 1];
        store_i64_le(output, 2 * x, distance);
        store_i64_le(output, 2 * x + 1, (long)site);
    }
    return (long)(n * 16);
}
