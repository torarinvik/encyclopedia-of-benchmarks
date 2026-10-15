module arithmetic_coding;

// Return the exact scaled lower bound produced by arithmetic coding.
fn long arithmetic_coding(long* input, usz length) @export("arithmetic_coding") {
    if (input == null || length < 2) return -1;
    long count = input[0];
    if (count < 1 || count > 12 || length != (usz)(count + 1)) return -1;

    long[256] frequency;
    long[257] cumulative;
    for (usz symbol = 0; symbol < 256; symbol++) {
        frequency[symbol] = 0;
        cumulative[symbol] = 0;
    }
    cumulative[256] = 0;
    for (usz index = 0; index < (usz)count; index++) {
        long symbol = input[index + 1];
        if (symbol < 0 || symbol > 255) return -1;
        frequency[(usz)symbol] += 1;
    }
    for (usz symbol = 0; symbol < 256; symbol++) {
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol];
    }

    long low = 0;
    long high = 1;
    for (usz index = 0; index < (usz)count; index++) {
        usz symbol = (usz)input[index + 1];
        long range = high - low;
        long base = low * count;
        high = base + range * cumulative[symbol + 1];
        low = base + range * cumulative[symbol];
    }
    return low;
}
