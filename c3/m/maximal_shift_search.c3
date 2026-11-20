module maximal_shift_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT_LENGTH = 4227;
const int ALPHABET = 4;

fn int ms_match_shift(const uchar* pattern, int m, const int* order_loc,
                      const int* order_symbol, int prefix_length, int shift) {
    while (shift < m) {
        int order_index = prefix_length - 1;
        while (order_index >= 0) {
            int pattern_index = order_loc[order_index] - shift;
            if (pattern_index >= 0 && order_symbol[order_index] != (int)pattern[pattern_index]) break;
            order_index -= 1;
        }
        if (order_index < 0) break;
        shift += 1;
    }
    return shift;
}

fn long maximal_shift_search(long* input, usz length) @export("maximal_shift_search") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n64 = input[0];
    long m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    int n = (int)n64;
    int m = (int)m64;
    if (length != 2 + (usz)n + (usz)m) return -1;
    uchar[MAX_TEXT] text = zeroed;
    uchar[MAX_PATTERN] pattern = zeroed;
    for (int q = 0; q < n; q++) {
        long value = input[2 + q];
        if (value < 0 || value >= ALPHABET) return -1;
        text[q] = (uchar)value;
    }
    for (int q = 0; q < m; q++) {
        long value = input[2 + n + q];
        if (value < 0 || value >= ALPHABET) return -1;
        pattern[q] = (uchar)value;
    }
    if (n < m) return 0;

    int[MAX_PATTERN] leading_shift = {};
    int[MAX_PATTERN + 1] order_loc = {};
    int[MAX_PATTERN + 1] order_symbol = {};
    int[ALPHABET] quick_shift = {};
    int[MAX_PATTERN + 1] adapted_shift = {};
    for (int i = 0; i < m; i++) {
        int previous = i - 1;
        while (previous >= 0 && pattern[previous] != pattern[i]) previous -= 1;
        leading_shift[i] = i - previous;
        int position = i;
        while (position > 0) {
            int prior_loc = order_loc[position - 1];
            if (leading_shift[prior_loc] > leading_shift[i] ||
                (leading_shift[prior_loc] == leading_shift[i] && prior_loc > i)) break;
            order_loc[position] = prior_loc;
            position -= 1;
        }
        order_loc[position] = i;
    }
    for (int i = 0; i < m; i++) order_symbol[i] = (int)pattern[order_loc[i]];
    order_loc[m] = m;
    order_symbol[m] = -1;
    for (int symbol = 0; symbol < ALPHABET; symbol++) quick_shift[symbol] = m + 1;
    for (int i = 0; i < m; i++) quick_shift[pattern[i]] = m - i;

    int shift = 1;
    adapted_shift[0] = 1;
    for (int prefix_length = 1; prefix_length <= m; prefix_length++) {
        shift = ms_match_shift(&pattern[0], m, &order_loc[0], &order_symbol[0], prefix_length, shift);
        adapted_shift[prefix_length] = shift;
    }
    for (int prefix_length = 0; prefix_length <= m; prefix_length++) {
        shift = adapted_shift[prefix_length];
        while (shift < m) {
            int pattern_index = order_loc[prefix_length] - shift;
            if (pattern_index < 0 || order_symbol[prefix_length] != (int)pattern[pattern_index]) break;
            shift += 1;
            shift = ms_match_shift(&pattern[0], m, &order_loc[0], &order_symbol[0], prefix_length, shift);
        }
        adapted_shift[prefix_length] = shift;
    }

    long count = 0;
    long offset_sum = 0;
    long offset_xor = 0;
    int start = 0;
    while (start <= n - m) {
        int compared = 0;
        while (compared < m && order_symbol[compared] == (int)text[start + order_loc[compared]]) compared += 1;
        if (compared == m) {
            count += 1;
            offset_sum += start;
            offset_xor ^= start;
        }
        int lookahead = start + m;
        if (lookahead >= n) break;
        int advance = adapted_shift[compared] > quick_shift[text[lookahead]]
                    ? adapted_shift[compared] : quick_shift[text[lookahead]];
        start += advance;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
