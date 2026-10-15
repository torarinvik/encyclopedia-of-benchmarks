module arithmetic_decoding;

// Decode an exact arithmetic-coded lower-bound numerator.
fn long arithmetic_decoding(long* input, usz length, char* output, usz capacity) @export("arithmetic_decoding") {
    if (input == null || length < 5) return -1;
    long count = input[0];
    long alphabet_size = input[1];
    if (count < 1 || count > 12 || alphabet_size < 1 || alphabet_size > count
        || length != (usz)(3 + 2 * alphabet_size)) return -1;

    long denominator = 1;
    for (long index = 0; index < count; index++) denominator *= count;
    long code = input[2];
    if (code < 0 || code >= denominator) return -1;

    long[12] symbols;
    long[13] cumulative;
    for (usz index = 0; index < 13; index++) cumulative[index] = 0;
    long total = 0;
    for (long index = 0; index < alphabet_size; index++) {
        long symbol = input[(usz)(3 + 2 * index)];
        long frequency = input[(usz)(4 + 2 * index)];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > count
            || (index > 0 && symbol <= symbols[(usz)(index - 1)])) return -1;
        symbols[(usz)index] = symbol;
        total += frequency;
        cumulative[(usz)(index + 1)] = total;
    }
    if (total != count) return -1;
    if (capacity < (usz)count || output == null) return -2;

    long low = 0;
    long high = 1;
    long scale = denominator / count;
    for (long step = 0; step < count; step++) {
        long range = high - low;
        long base = low * count;
        bool found = false;
        for (long index = 0; index < alphabet_size; index++) {
            long symbol_low = base + range * cumulative[(usz)index];
            long symbol_high = base + range * cumulative[(usz)(index + 1)];
            if (code >= symbol_low * scale && code < symbol_high * scale) {
                output[(usz)step] = (char)symbols[(usz)index];
                low = symbol_low;
                high = symbol_high;
                found = true;
                break;
            }
        }
        if (!found) return -1;
        if (step + 1 < count) scale /= count;
    }
    return count;
}
