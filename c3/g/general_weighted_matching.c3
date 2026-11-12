module general_weighted_matching;

const int MAX_N = 16;
const int MAX_OUTPUT_WORDS = 2 + MAX_N;
const usz MAX_STATES = 1 << MAX_N;
const usz MAX_INPUT_VALUES = 2 + 3 * (usz)(MAX_N * (MAX_N - 1) / 2) + 1;
const long MAX_WEIGHT = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long general_weighted_matching(long* input, usz length, char* output,
    usz capacity) @export("general_weighted_matching") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long nv = input[0], mv = input[1];
    if (nv < 1 || nv > MAX_N || mv < 0 || mv > nv * (nv - 1) / 2) return -1;
    int n = (int)nv, m = (int)mv;
    if (length != 2 + 3 * (usz)m) return -1;

    long[MAX_N][MAX_N] weights;
    bool[MAX_N][MAX_N] present;
    for (int u = 0; u < n; u++) for (int v = 0; v < n; v++) {
        weights[u][v] = 0;
        present[u][v] = false;
    }
    usz cursor = 2;
    for (int edge = 0; edge < m; edge++) {
        long uv = input[cursor++], vv = input[cursor++], weight = input[cursor++];
        if (uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv ||
            weight < 1 || weight > MAX_WEIGHT) return -1;
        int u = (int)uv, v = (int)vv;
        if (present[u][v]) return -1;
        present[u][v] = true;
        present[v][u] = true;
        weights[u][v] = weight;
        weights[v][u] = weight;
    }

    long[MAX_STATES] dp;
    for (usz mask = 0; mask < MAX_STATES; mask++) dp[mask] = 0;
    usz state_count = 1 << n;
    for (usz mask = 1; mask < state_count; mask++) {
        usz bit = mask & (~mask + 1);
        int vertex = 0;
        while ((bit >> vertex) != 1) vertex++;
        usz remainder = mask ^ bit;
        dp[mask] = dp[remainder];
        for (int partner = vertex + 1; partner < n; partner++) {
            usz partner_bit = 1 << partner;
            if ((remainder & partner_bit) == 0 || !present[vertex][partner]) continue;
            long candidate = weights[vertex][partner] + dp[remainder ^ partner_bit];
            if (candidate > dp[mask]) dp[mask] = candidate;
        }
    }

    long[MAX_OUTPUT_WORDS] words;
    int pair_count = 0;
    usz mask = state_count - 1;
    while (mask != 0) {
        usz bit = mask & (~mask + 1);
        int vertex = 0;
        while ((bit >> vertex) != 1) vertex++;
        usz remainder = mask ^ bit;
        if (dp[mask] == dp[remainder]) { mask = remainder; continue; }
        int selected = -1;
        for (int partner = vertex + 1; partner < n; partner++) {
            usz partner_bit = 1 << partner;
            if ((remainder & partner_bit) != 0 && present[vertex][partner] &&
                weights[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask]) {
                selected = partner;
                break;
            }
        }
        if (selected < 0) return -1;
        words[2 + 2 * pair_count] = vertex;
        words[3 + 2 * pair_count] = selected;
        pair_count++;
        mask = remainder ^ (1 << selected);
    }

    words[0] = pair_count;
    words[1] = dp[state_count - 1];
    usz output_words = 2 + 2 * (usz)pair_count;
    usz output_bytes = 8 * output_words;
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < output_words; word++)
        store_i64_le(output, 8 * word, words[word]);
    return (long)output_bytes;
}
