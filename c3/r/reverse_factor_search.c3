module reverse_factor_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT_LENGTH = 4227;
const usz MAX_STATES = 2 * MAX_PATTERN + 1;

fn long reverse_factor_search(long* input, usz length) @export("reverse_factor_search") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n64 = input[0];
    long m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    usz n = (usz)n64;
    usz m = (usz)m64;
    if (length != 2 + n + m) return -1;
    uchar[MAX_TEXT] text = zeroed;
    uchar[MAX_PATTERN] pattern = zeroed;
    for (usz q = 0; q < n; q++) {
        long value = input[2 + q];
        if (value < 0 || value > 3) return -1;
        text[q] = (uchar)value;
    }
    for (usz q = 0; q < m; q++) {
        long value = input[2 + n + q];
        if (value < 0 || value > 3) return -1;
        pattern[q] = (uchar)value;
    }
    if (n < m) return 0;

    int[MAX_STATES][4] transitions = {};
    int[MAX_STATES] suffix_link = {};
    int[MAX_STATES] max_length = {};
    bool[MAX_STATES] terminal = {};
    for (usz state = 0; state < MAX_STATES; state++) {
        suffix_link[state] = -1;
        for (usz symbol = 0; symbol < 4; symbol++) transitions[state][symbol] = -1;
    }
    int state_count = 1;
    int last = 0;
    for (int pos = 0; (usz)pos < m; pos++) {
        int symbol = (int)pattern[m - 1 - (usz)pos];
        int current = state_count++;
        max_length[current] = max_length[last] + 1;
        int predecessor = last;
        while (predecessor >= 0 && transitions[predecessor][symbol] < 0) {
            transitions[predecessor][symbol] = current;
            predecessor = suffix_link[predecessor];
        }
        if (predecessor < 0) {
            suffix_link[current] = 0;
        } else {
            int target = transitions[predecessor][symbol];
            if (max_length[predecessor] + 1 == max_length[target]) {
                suffix_link[current] = target;
            } else {
                int clone = state_count++;
                for (int c = 0; c < 4; c++) transitions[clone][c] = transitions[target][c];
                max_length[clone] = max_length[predecessor] + 1;
                suffix_link[clone] = suffix_link[target];
                while (predecessor >= 0 && transitions[predecessor][symbol] == target) {
                    transitions[predecessor][symbol] = clone;
                    predecessor = suffix_link[predecessor];
                }
                suffix_link[target] = clone;
                suffix_link[current] = clone;
            }
        }
        last = current;
    }
    int state = last;
    while (state >= 0) {
        terminal[state] = true;
        state = suffix_link[state];
    }

    long count = 0;
    long offset_sum = 0;
    long offset_xor = 0;
    int period = (int)m;
    int start = 0;
    while ((usz)start <= n - m) {
        int index = (int)m - 1;
        state = 0;
        int shift = (int)m;
        while (start + index >= 0) {
            int target = transitions[state][text[start + index]];
            if (target < 0) break;
            state = target;
            if (terminal[state]) {
                period = shift;
                shift = index;
            }
            index--;
        }
        if (index < 0) {
            count++;
            offset_sum += start;
            offset_xor ^= start;
            shift = period;
        }
        start += shift;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
