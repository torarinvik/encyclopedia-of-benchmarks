module weak_stable_matching_ties_incomplete;

const usz MAX_N = 6;
const usz MAX_INPUT = 73;
const usz MAX_OUTPUT_BYTES = 104;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long weak_stable_matching_ties_incomplete(long* input, usz length, char* output, usz capacity)
        @export("weak_stable_matching_ties_incomplete") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N.long()) return -1;
    usz n = n_raw.usz(), side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;
    long[MAX_N][MAX_N] men_rank = zeroed, women_rank = zeroed;
    usz[MAX_N][MAX_N] choices = zeroed;
    usz[MAX_N] choice_count = zeroed;
    for (usz man = 0; man < n; man += 1) for (usz woman = 0; woman < n; woman += 1) {
        long rank = input[1 + man * n + woman];
        if (rank < 0 || rank > n_raw) return -1;
        men_rank[man][woman] = rank;
    }
    for (usz woman = 0; woman < n; woman += 1) for (usz man = 0; man < n; man += 1) {
        long rank = input[1 + side_size + woman * n + man];
        if (rank < 0 || rank > n_raw || (rank > 0) != (men_rank[man][woman] > 0)) return -1;
        women_rank[woman][man] = rank;
    }
    for (usz man = 0; man < n; man += 1) for (usz woman = 0; woman < n; woman += 1) {
        if (men_rank[man][woman] == 0) continue;
        usz at = choice_count[man];
        while (at > 0) {
            usz prior = choices[man][at - 1];
            if (men_rank[man][prior] < men_rank[man][woman] || (men_rank[man][prior] == men_rank[man][woman] && prior < woman)) break;
            choices[man][at] = prior;
            at -= 1;
        }
        choices[man][at] = woman;
        choice_count[man] += 1;
    }
    int[MAX_N] man_partner, woman_partner;
    usz[MAX_N] next_choice = zeroed;
    for (usz i = 0; i < n; i += 1) { man_partner[i] = -1; woman_partner[i] = -1; }
    while (true) {
        int man = -1;
        for (usz candidate = 0; candidate < n; candidate += 1)
            if (man_partner[candidate] < 0 && next_choice[candidate] < choice_count[candidate]) { man = candidate.int(); break; }
        if (man < 0) break;
        usz m = man.usz(), woman = choices[m][next_choice[m]];
        next_choice[m] += 1;
        int incumbent = woman_partner[woman];
        if (incumbent < 0 || women_rank[woman][m] < women_rank[woman][incumbent.usz()] ||
                (women_rank[woman][m] == women_rank[woman][incumbent.usz()] && man < incumbent)) {
            woman_partner[woman] = man;
            man_partner[m] = woman.int();
            if (incumbent >= 0) man_partner[incumbent.usz()] = -1;
        }
    }
    long[1 + 2 * MAX_N] words = zeroed;
    usz pairs = 0;
    for (usz man = 0; man < n; man += 1) if (man_partner[man] >= 0) {
        words[1 + 2 * pairs] = man.long();
        words[2 + 2 * pairs] = man_partner[man].long();
        pairs += 1;
    }
    words[0] = pairs.long();
    usz output_bytes = 8 * (1 + 2 * pairs);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz word = 0; word < 1 + 2 * pairs; word += 1) store_i64_le(&staged[0], 8 * word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
