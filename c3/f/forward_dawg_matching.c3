module forward_dawg_matching;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;
const usz MAX_STATES = 2 * MAX_PATTERN + 2;

struct SuffixAutomaton {
    long[MAX_STATES][4] transition;
    long[MAX_STATES] suffix_link;
    long[MAX_STATES] max_length;
    usz state_count;
}

fn void fdm_init(SuffixAutomaton* sam) {
    sam.state_count = 1;
    for (usz state = 0; state < MAX_STATES; state += 1) {
        sam.suffix_link[state] = -1;
        sam.max_length[state] = 0;
        for (usz symbol = 0; symbol < 4; symbol += 1) sam.transition[state][symbol] = -1;
    }
}

fn long fdm_extend(SuffixAutomaton* sam, long last, usz symbol) {
    if (sam.state_count >= MAX_STATES) return -1;
    usz current = sam.state_count;
    sam.state_count += 1;
    sam.max_length[current] = sam.max_length[(usz)last] + 1;
    long state = last;
    while (state >= 0 && sam.transition[(usz)state][symbol] < 0) {
        sam.transition[(usz)state][symbol] = (long)current;
        state = sam.suffix_link[(usz)state];
    }
    if (state < 0) {
        sam.suffix_link[current] = 0;
    } else {
        long target = sam.transition[(usz)state][symbol];
        if (sam.max_length[(usz)state] + 1 == sam.max_length[(usz)target]) {
            sam.suffix_link[current] = target;
        } else {
            if (sam.state_count >= MAX_STATES) return -1;
            usz clone = sam.state_count;
            sam.state_count += 1;
            sam.max_length[clone] = sam.max_length[(usz)state] + 1;
            sam.suffix_link[clone] = sam.suffix_link[(usz)target];
            for (usz c = 0; c < 4; c += 1) sam.transition[clone][c] = sam.transition[(usz)target][c];
            while (state >= 0 && sam.transition[(usz)state][symbol] == target) {
                sam.transition[(usz)state][symbol] = (long)clone;
                state = sam.suffix_link[(usz)state];
            }
            sam.suffix_link[(usz)target] = (long)clone;
            sam.suffix_link[current] = (long)clone;
        }
    }
    return (long)current;
}

fn long fdm_search(SuffixAutomaton* sam, long* text, usz n, usz m) {
    usz state = 0;
    long matched = 0, count = 0, offset_sum = 0, offset_xor = 0;
    for (usz position = 0; position < n; position += 1) {
        usz symbol = (usz)text[position];
        long target = sam.transition[state][symbol];
        if (target >= 0) {
            matched += 1;
            state = (usz)target;
        } else {
            while (state != 0 && sam.transition[state][symbol] < 0)
                state = (usz)sam.suffix_link[state];
            target = sam.transition[state][symbol];
            if (target >= 0) {
                matched = sam.max_length[state] + 1;
                state = (usz)target;
            } else {
                matched = 0;
                state = 0;
            }
        }
        if (matched == (long)m) {
            long start = (long)(position + 1 - m);
            count += 1;
            offset_sum += start;
            offset_xor ^= start;
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

fn long forward_dawg_matching(long* input, usz length) @export("forward_dawg_matching") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > (long)MAX_TEXT || m_value < 1 || m_value > (long)MAX_PATTERN) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i += 1)
        if (input[2 + i] < 0 || input[2 + i] > 3) return -1;
    long[MAX_PATTERN] pattern = zeroed;
    for (usz i = 0; i < m; i += 1) pattern[i] = input[2 + n + i];
    SuffixAutomaton sam;
    fdm_init(&sam);
    long last = 0;
    for (usz i = 0; i < m; i += 1) {
        last = fdm_extend(&sam, last, (usz)pattern[i]);
        if (last < 0) return -1;
    }
    return fdm_search(&sam, input + 2, n, m);
}
