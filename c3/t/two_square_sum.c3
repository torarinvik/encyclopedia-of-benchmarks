module two_square_sum;

const usz MAX_Q = 8;
const long MAX_N = 10000;

fn long integer_sqrt(long value) {
    long low = 0;
    long high = value + 1;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn void write_u32(char* output, usz offset, u32 value) {
    output[offset] = (char)(value & 255);
    output[offset + 1] = (char)((value >> 8) & 255);
    output[offset + 2] = (char)((value >> 16) & 255);
    output[offset + 3] = (char)((value >> 24) & 255);
}

fn long two_square_sum(long* input, usz length, char* output, usz capacity)
    @export("two_square_sum") {
    if (input == null || length < 2 || length > MAX_Q + 1) return -1;
    long q64 = input[0];
    if (q64 < 1 || q64 > (long)MAX_Q) return -1;
    usz q = (usz)q64;
    if (length != q + 1) return -1;

    long[MAX_Q] numbers = zeroed;
    usz[MAX_Q] counts = zeroed;
    usz total_pairs = 0;
    for (usz query = 0; query < q; query += 1) {
        long n = input[query + 1];
        if (n < 0 || n > MAX_N) return -1;
        numbers[query] = n;
        for (long a = 0; a * a <= n; a += 1) {
            long remainder = n - a * a;
            long b = integer_sqrt(remainder);
            if (b * b == remainder) counts[query] += 1;
        }
        total_pairs += counts[query];
    }

    usz required = 4 * (q + 2 * total_pairs);
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    for (usz query = 0; query < q; query += 1) {
        write_u32(output, offset, (u32)counts[query]);
        offset += 4;
        long n = numbers[query];
        for (long a = 0; a * a <= n; a += 1) {
            long remainder = n - a * a;
            long b = integer_sqrt(remainder);
            if (b * b != remainder) continue;
            write_u32(output, offset, (u32)a);
            write_u32(output, offset + 4, (u32)b);
            offset += 8;
        }
    }
    return (long)offset;
}
