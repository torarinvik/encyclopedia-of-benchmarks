module elias_fano_monotone_sequence;

const int MAX_N = 32;
const int MAX_HIGH_BITS = 3 * MAX_N;
const int MAX_HIGH_WORDS = (MAX_HIGH_BITS + 63) / 64;

fn long elias_fano_monotone_sequence(long* input, usz length)
        @export("elias_fano_monotone_sequence") {
    if (input == null || length < 3 || length > MAX_N + 3) return -1;
    long raw_n = input[0], upper_bound = input[1];
    if (raw_n < 1 || raw_n > MAX_N || upper_bound < 0 || upper_bound > 1000000 ||
        raw_n > upper_bound + 1 || length != (usz)(raw_n + 2)) return -1;
    int n = (int)raw_n;

    long[MAX_N] values = zeroed, low_parts = zeroed;
    for (int i = 0; i < n; i += 1) {
        long value = input[i + 2];
        if (value < 0 || value > upper_bound || (i > 0 && value < values[i - 1])) return -1;
        values[i] = value;
    }

    int low_width = 0;
    long low_scale = 1;
    while ((long)n * (low_scale << 1) <= upper_bound + 1) {
        low_scale <<= 1;
        low_width += 1;
    }
    ulong low_mask = ((ulong)1 << low_width) - 1ul;
    for (int i = 0; i < n; i += 1) low_parts[i] = (long)((ulong)values[i] & low_mask);

    long high_length = (upper_bound >> low_width) + n;
    if (high_length < 1 || high_length > MAX_HIGH_BITS) return -1;
    ulong[MAX_HIGH_WORDS] high_bits = zeroed;
    for (int i = 0; i < n; i += 1) {
        long position = (values[i] >> low_width) + i;
        if (position < 0 || position >= high_length) return -1;
        usz word = (usz)(position / 64), bit = (usz)(position % 64);
        high_bits[word] |= 1ul << bit;
    }

    long checksum = 0;
    int item_index = 0;
    for (long position = 0; position < high_length; position += 1) {
        usz word = (usz)(position / 64), bit = (usz)(position % 64);
        if (((high_bits[word] >> bit) & 1ul) == 0ul) continue;
        if (item_index >= n || position < item_index) return -1;
        long high_part = position - item_index;
        long decoded = (high_part << low_width) | low_parts[item_index];
        checksum += (long)(item_index + 1) * decoded;
        item_index += 1;
    }
    return item_index == n ? checksum : -1;
}
