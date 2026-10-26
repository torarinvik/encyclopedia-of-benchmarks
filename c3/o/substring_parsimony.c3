module substring_parsimony;

const usz MAX_STATES = 4;
const usz MAX_INPUT = 26;
const usz MAX_ASSIGNMENTS = 1024;
const usz MAX_OUTPUT_WORDS = 2 + 5 * MAX_ASSIGNMENTS;
const long INF = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long substring_parsimony(long* input, usz length, char* output, usz capacity) @export("substring_parsimony") {
    if (input == null || length < 10 || length > MAX_INPUT) return -1;
    long q_raw = input[0], threshold = input[1];
    if (q_raw < 1 || q_raw > (long)MAX_STATES || threshold < 0 || threshold > 36) return -1;
    usz q = (usz)q_raw;
    if (length != 9 + q * q) return -1;
    long[2][2] child = zeroed;
    child[0][0] = input[2]; child[0][1] = input[3];
    child[1][0] = input[4]; child[1][1] = input[5];
    for (usz node = 0; node < 2; node += 1) {
        if (child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
            || child[node][0] == child[node][1]) return -1;
    }
    long root_leaf = -1;
    if (child[0][0] == 1) root_leaf = child[0][1];
    else if (child[0][1] == 1) root_leaf = child[0][0];
    if (root_leaf < 2 || root_leaf > 4) return -1;
    if (child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
        || child[1][0] == child[1][1] || child[1][0] == root_leaf || child[1][1] == root_leaf) return -1;
    for (long leaf = 2; leaf <= 4; leaf += 1)
        if (leaf != root_leaf && child[1][0] != leaf && child[1][1] != leaf) return -1;

    long[3] masks = {input[6], input[7], input[8]};
    ulong universe = (1ul << q) - 1;
    for (usz leaf = 0; leaf < 3; leaf += 1)
        if (masks[leaf] <= 0 || (ulong)masks[leaf] > universe) return -1;
    long[MAX_STATES][MAX_STATES] distance = zeroed;
    for (usz i = 0; i < q; i += 1) {
        for (usz j = 0; j < q; j += 1) {
            long value = input[9 + i * q + j];
            if (value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0)) return -1;
            distance[i][j] = value;
            if (value != input[9 + j * q + i]) return -1;
        }
    }
    for (usz i = 0; i < q; i += 1)
        for (usz j = 0; j < q; j += 1)
            for (usz k = 0; k < q; k += 1)
                if (distance[i][k] > distance[i][j] + distance[j][k]) return -1;

    long[5][MAX_STATES] dp = zeroed;
    for (usz node = 0; node < 5; node += 1)
        for (usz state = 0; state < q; state += 1) dp[node][state] = INF;
    for (usz leaf = 2; leaf <= 4; leaf += 1)
        for (usz state = 0; state < q; state += 1)
            if (((ulong)masks[leaf - 2] & (1ul << state)) != 0) dp[leaf][state] = 0;
    for (long node = 1; node >= 0; node -= 1) {
        for (usz state = 0; state < q; state += 1) {
            long total = 0;
            for (usz slot = 0; slot < 2; slot += 1) {
                usz descendant = (usz)child[node][slot];
                long best = INF;
                for (usz other = 0; other < q; other += 1) {
                    long candidate = dp[descendant][other] + distance[state][other];
                    if (candidate < best) best = candidate;
                }
                total += best;
            }
            dp[node][state] = total;
        }
    }
    long optimum = INF;
    for (usz state = 0; state < q; state += 1) if (dp[0][state] < optimum) optimum = dp[0][state];
    if (optimum >= INF) return -1;
    long[MAX_OUTPUT_WORDS] staged = zeroed;
    staged[0] = optimum;
    usz words = 2;
    if (optimum <= threshold) {
        for (usz x0 = 0; x0 < q; x0 += 1) {
            for (usz x1 = 0; x1 < q; x1 += 1) {
                for (usz x2 = 0; x2 < q; x2 += 1) {
                    if (((ulong)masks[0] & (1ul << x2)) == 0) continue;
                    for (usz x3 = 0; x3 < q; x3 += 1) {
                        if (((ulong)masks[1] & (1ul << x3)) == 0) continue;
                        for (usz x4 = 0; x4 < q; x4 += 1) {
                            if (((ulong)masks[2] & (1ul << x4)) == 0) continue;
                            usz[5] label = {x0, x1, x2, x3, x4};
                            long score = 0;
                            for (usz node = 0; node < 2; node += 1)
                                for (usz slot = 0; slot < 2; slot += 1)
                                    score += distance[label[node]][label[(usz)child[node][slot]]];
                            if (score == optimum)
                                for (usz node = 0; node < 5; node += 1) { staged[words] = (long)label[node]; words += 1; }
                        }
                    }
                }
            }
        }
    }
    staged[1] = (long)((words - 2) / 5);
    usz bytes = words * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < words; word += 1) store_i64_le(output, word * 8, staged[word]);
    return (long)bytes;
}
