module bipartite_minimum_vertex_cover;

const usz MAX_SIDE = 8;
const usz MAX_VERTICES = 16;
const usz MAX_PARSEABLE_INPUT = 11;

fn bool augment_left(int left, int left_count, int right_count, long* rows,
                     long* states, long* match_right, bool* seen) {
    for (int right = 0; right < right_count; right++) {
        if ((rows[left] & (1L << right)) == 0 || seen[right] || states[left_count + right] != -1) continue;
        seen[right] = true;
        int owner = (int)match_right[right];
        if (owner == -1 || augment_left(owner, left_count, right_count, rows, states, match_right, seen)) {
            match_right[right] = left;
            return true;
        }
    }
    return false;
}

fn int maximum_matching(int left_count, int right_count, long* rows,
                        long* states, long* match_right) {
    for (int right = 0; right < right_count; right++) match_right[right] = -1;
    int size = 0;
    for (int left = 0; left < left_count; left++) {
        if (states[left] != -1) continue;
        bool[8] seen = zeroed;
        if (augment_left(left, left_count, right_count, rows, states, match_right, &seen[0])) size++;
    }
    return size;
}

fn int bit_count(long value) {
    int count = 0;
    while (value != 0) { count += (int)(value & 1); value >>= 1; }
    return count;
}

fn long alternating_cover(int left_count, int right_count, long* rows, long* match_right) {
    bool[8] matched_left = zeroed;
    bool[8] reached_left = zeroed;
    bool[8] reached_right = zeroed;
    int[8] queue;
    int head = 0, tail = 0;
    for (int right = 0; right < right_count; right++)
        if (match_right[right] >= 0) matched_left[(int)match_right[right]] = true;
    for (int left = 0; left < left_count; left++) {
        if (!matched_left[left]) { reached_left[left] = true; queue[tail++] = left; }
    }
    while (head < tail) {
        int left = queue[head++];
        for (int right = 0; right < right_count; right++) {
            if ((rows[left] & (1L << right)) == 0 || reached_right[right] || match_right[right] < 0) continue;
            reached_right[right] = true;
            int owner = (int)match_right[right];
            if (!reached_left[owner]) { reached_left[owner] = true; queue[tail++] = owner; }
        }
    }
    long result = 0;
    for (int left = 0; left < left_count; left++) if (!reached_left[left]) result |= 1L << left;
    for (int right = 0; right < right_count; right++)
        if (reached_right[right]) result |= 1L << (left_count + right);
    return result;
}

fn int minimum_completion_size(int left_count, int right_count, long* rows, long* input_states) {
    long[16] states;
    for (int i = 0; i < left_count + right_count; i++) states[i] = input_states[i];
    bool changed;
    do {
        changed = false;
        for (int left = 0; left < left_count; left++) {
            for (int right = 0; right < right_count; right++) {
                if ((rows[left] & (1L << right)) == 0) continue;
                int right_vertex = left_count + right;
                if (states[left] == 0 && states[right_vertex] == 0) return -1;
                if (states[left] == 0 && states[right_vertex] == -1) {
                    states[right_vertex] = 1; changed = true;
                } else if (states[right_vertex] == 0 && states[left] == -1) {
                    states[left] = 1; changed = true;
                }
            }
        }
    } while (changed);
    int forced_in = 0;
    for (int i = 0; i < left_count + right_count; i++) if (states[i] == 1) forced_in++;
    long[8] residual_match;
    return forced_in + maximum_matching(left_count, right_count, rows, &states[0], &residual_match[0]);
}

fn long canonical_cover(int left_count, int right_count, long* rows, int optimum) {
    long[16] states;
    for (int i = 0; i < left_count + right_count; i++) states[i] = -1;
    for (int vertex = 0; vertex < left_count + right_count; vertex++) {
        states[vertex] = 0;
        if (minimum_completion_size(left_count, right_count, rows, &states[0]) != optimum) states[vertex] = 1;
    }
    long result = 0;
    for (int vertex = 0; vertex < left_count + right_count; vertex++)
        if (states[vertex] == 1) result |= 1L << vertex;
    return result;
}

fn long bipartite_minimum_vertex_cover(long* input, usz length) @export("bipartite_minimum_vertex_cover") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long left_value = input[0], right_value = input[1];
    if (left_value < 0 || left_value > (long)MAX_SIDE || right_value < 0 || right_value > (long)MAX_SIDE) return -1;
    int left_count = (int)left_value, right_count = (int)right_value;
    if (length != (usz)(left_count + 2)) return -1;
    long right_domain = (1L << right_count) - 1;
    long[8] rows = zeroed;
    for (int left = 0; left < left_count; left++) {
        long row = input[2 + left];
        if (row < 0 || (row & ~right_domain) != 0) return -1;
        rows[left] = row;
    }
    long[16] free_states;
    for (usz i = 0; i < MAX_VERTICES; i++) free_states[i] = -1;
    long[8] match_right;
    int matching_size = maximum_matching(left_count, right_count, &rows[0], &free_states[0], &match_right[0]);
    long seed = alternating_cover(left_count, right_count, &rows[0], &match_right[0]);
    int optimum = bit_count(seed);
    if (optimum != matching_size) return -1;
    return canonical_cover(left_count, right_count, &rows[0], optimum);
}
