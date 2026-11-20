module list_ranking_random_mate;
const usz MAX_N = 8; const usz MAX_ROUNDS = 32;
const usz MAX_INPUT = 275; const usz MAX_OUTPUT = 64;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long list_ranking_random_mate(long* input, usz length, char* output,
                                 usz capacity) @export("list_ranking_random_mate") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n_value = input[0], head_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || head_value < 0 || head_value >= n_value)
        return -1;
    usz n = (usz)n_value, head = (usz)head_value;
    if (length < 3 + 2*n) return -1;
    long rounds_value = input[2 + 2*n];
    if (rounds_value < 0 || rounds_value > (long)MAX_ROUNDS ||
        length != 3 + 2*n + (usz)rounds_value*n) return -1;
    usz rounds = (usz)rounds_value;
    long[MAX_N] weight = zeroed, successor = zeroed;
    usz[MAX_N] indegree = zeroed;
    usz tail_count = 0;
    for (usz index = 0; index < n; index += 1) {
        weight[index] = input[2 + index];
        successor[index] = input[2 + n + index];
        if (weight[index] < 1 || weight[index] > 10000 || successor[index] < -1 ||
            successor[index] >= n_value) return -1;
        if (successor[index] == -1) tail_count += 1;
        else {
            usz target = (usz)successor[index];
            indegree[target] += 1;
            if (indegree[target] > 1) return -1;
        }
    }
    if (tail_count != 1 || indegree[head] != 0) return -1;
    usz coin_start = 3 + 2*n;
    for (usz index = 0; index < rounds*n; index += 1)
        if (input[coin_start + index] < 0 || input[coin_start + index] > 1) return -1;

    bool[MAX_N] seen = zeroed;
    usz path_length = 0;
    long node = head_value;
    while (node != -1) {
        usz index = (usz)node;
        if (seen[index] || path_length == n) return -1;
        seen[index] = true;
        path_length += 1;
        node = successor[index];
    }
    if (path_length != n) return -1;

    bool[MAX_N] active = zeroed;
    long[MAX_N] removal_round = zeroed;
    for (usz index = 0; index < n; index += 1) { active[index] = true; removal_round[index] = -1; }
    for (usz round = 0; round < rounds && successor[head] != -1; round += 1) {
        long[MAX_N] old_successor = zeroed, old_weight = zeroed;
        bool[MAX_N] remove = zeroed;
        for (usz index = 0; index < n; index += 1) {
            old_successor[index] = successor[index]; old_weight[index] = weight[index];
        }
        usz coin_offset = coin_start + round*n;
        for (usz index = 0; index < n; index += 1) {
            long target_value = old_successor[index];
            if (active[index] && target_value != -1 && input[coin_offset + index] == 0 &&
                input[coin_offset + (usz)target_value] == 1) {
                usz target = (usz)target_value; remove[target] = true; removal_round[target] = (long)round;
            }
        }
        for (usz index = 0; index < n; index += 1) {
            long target_value = old_successor[index];
            if (active[index] && target_value != -1 && remove[(usz)target_value]) {
                usz target = (usz)target_value;
                weight[index] = old_weight[index] + old_weight[target];
                successor[index] = old_successor[target];
            }
        }
        for (usz index = 0; index < n; index += 1) if (remove[index]) active[index] = false;
    }
    if (successor[head] != -1) return -1;

    long[MAX_N] rank = zeroed;
    for (usz index = 0; index < n; index += 1) rank[index] = weight[index];
    usz remaining = rounds;
    while (remaining > 0) {
        remaining -= 1;
        for (usz index = 0; index < n; index += 1)
            if (removal_round[index] == (long)remaining && successor[index] != -1)
                rank[index] += rank[(usz)successor[index]];
    }
    usz output_bytes = 8*n;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz index = 0; index < n; index += 1) put64(&staged[0], 8*index, rank[index]);
    for (usz index = 0; index < output_bytes; index += 1) output[index] = staged[index];
    return (long)output_bytes;
}
