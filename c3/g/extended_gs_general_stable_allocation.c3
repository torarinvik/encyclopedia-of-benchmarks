module extended_gs_general_stable_allocation;

const usz MAX_EDGES = 4;
const usz MAX_INPUT = 19;
const usz MAX_OUTPUT_BYTES = 104;
const long INF = 255;

fn long utility(long first, long second, long count) {
    if (count == 0) return 0;
    if (count == 1) return first;
    return first + second;
}

fn void choose_men(usz men, usz women, long quota, usz edges, long* mf, long* ms,
                   long* lower, long* upper, long* answer) {
    long best_value = -1;
    usz codes = 1;
    for (usz e = 0; e < edges; e++) codes *= 3;
    for (usz code = 0; code < codes; code++) {
        usz rem = code;
        long[MAX_EDGES] candidate = zeroed;
        for (usz e = edges; e > 0; e--) { usz index = e - 1; candidate[index] = (long)(rem % 3); rem /= 3; }
        bool feasible = true;
        for (usz e = 0; e < edges; e++) if (candidate[e] < lower[e] || candidate[e] > upper[e]) feasible = false;
        for (usz i = 0; i < men; i++) {
            long total = 0;
            for (usz j = 0; j < women; j++) total += candidate[i * women + j];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        long value = 0;
        for (usz e = 0; e < edges; e++) value += utility(mf[e], ms[e], candidate[e]);
        if (value > best_value) { best_value = value; for (usz e = 0; e < edges; e++) answer[e] = candidate[e]; }
    }
}

fn void choose_women(usz men, usz women, long quota, usz edges, long* wf, long* ws,
                     long* upper, long* answer) {
    long best_value = -1;
    usz codes = 1;
    for (usz e = 0; e < edges; e++) codes *= 3;
    for (usz code = 0; code < codes; code++) {
        usz rem = code;
        long[MAX_EDGES] candidate = zeroed;
        for (usz e = edges; e > 0; e--) { usz index = e - 1; candidate[index] = (long)(rem % 3); rem /= 3; }
        bool feasible = true;
        for (usz e = 0; e < edges; e++) if (candidate[e] > upper[e]) feasible = false;
        for (usz j = 0; j < women; j++) {
            long total = 0;
            for (usz i = 0; i < men; i++) total += candidate[i * women + j];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        long value = 0;
        for (usz e = 0; e < edges; e++) value += utility(wf[e], ws[e], candidate[e]);
        if (value > best_value) { best_value = value; for (usz e = 0; e < edges; e++) answer[e] = candidate[e]; }
    }
}

fn void put_i64(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uint8)(bits >> (8 * byte));
}

long extended_gs_general_stable_allocation(long* input, usz length, uint8* output, usz capacity)
        @export("extended_gs_general_stable_allocation") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > 2 || input[1] < 1 || input[1] > 2 || input[2] < 1 || input[2] > 2) return -1;
    usz men = (usz)input[0], women = (usz)input[1];
    long quota = input[2];
    usz edges = men * women;
    if (length != 3 + 4 * edges) return -1;
    long[MAX_EDGES] mf = zeroed, ms = zeroed, wf = zeroed, ws = zeroed;
    for (usz e = 0; e < edges; e++) {
        mf[e] = input[3 + 4 * e]; ms[e] = input[4 + 4 * e];
        wf[e] = input[5 + 4 * e]; ws[e] = input[6 + 4 * e];
        if (mf[e] < 0 || mf[e] > 8 || ms[e] < 0 || ms[e] > mf[e] ||
            wf[e] < 0 || wf[e] > 8 || ws[e] < 0 || ws[e] > wf[e]) return -1;
    }
    long[MAX_EDGES] x_w = zeroed, z_m, z_w = zeroed, x_m = zeroed, next_w = zeroed;
    for (usz e = 0; e < edges; e++) z_m[e] = INF;
    bool converged = false;
    for (usz iteration = 0; iteration < 3 * edges + 2; iteration++) {
        choose_men(men, women, quota, edges, &mf[0], &ms[0], &x_w[0], &z_m[0], &x_m[0]);
        choose_women(men, women, quota, edges, &wf[0], &ws[0], &x_m[0], &next_w[0]);
        converged = true;
        for (usz e = 0; e < edges; e++) if (x_m[e] != next_w[e]) converged = false;
        if (converged) break;
        for (usz e = 0; e < edges; e++) {
            if (x_m[e] > next_w[e]) { z_m[e] = next_w[e]; z_w[e] = INF; }
            x_w[e] = next_w[e];
        }
    }
    if (!converged) return -1;
    usz output_values = 1 + 3 * edges, output_bytes = 8 * output_values;
    if (output == null || capacity < output_bytes) return -2;
    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    put_i64(&staged[0], 0, (long)edges);
    for (usz e = 0; e < edges; e++) {
        put_i64(&staged[0], 8 * (1 + e), x_m[e]);
        put_i64(&staged[0], 8 * (1 + edges + e), z_m[e]);
        put_i64(&staged[0], 8 * (1 + 2 * edges + e), z_w[e] > x_m[e] ? z_w[e] : x_m[e]);
    }
    for (usz byte = 0; byte < output_bytes; byte++) output[byte] = staged[byte];
    return (long)output_bytes;
}
