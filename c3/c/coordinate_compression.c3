module coordinate_compression;
const usz MAX_N = 128;

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long coordinate_compression(long* input, usz length, char* output, usz capacity) @export("coordinate_compression") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    long[MAX_N] sorted;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
        sorted[i] = value;
    }
    if (capacity < n * 8 || (n > 0 && output == null)) return -2;
    for (usz i = 1; i < n; i++) {
        long value = sorted[i];
        usz j = i;
        while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; j--; }
        sorted[j] = value;
    }
    long[MAX_N] ranks;
    long rank = -1;
    for (usz i = 0; i < n; i++) {
        if (i == 0 || sorted[i] != sorted[i - 1]) rank++;
        ranks[i] = rank;
    }
    for (usz i = 0; i < n; i++) {
        usz low = 0, high = n;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (sorted[middle] < input[i + 1]) low = middle + 1; else high = middle;
        }
        put_i64_le(ranks[low], output, i * 8);
    }
    return (long)(n * 8);
}
