module signed_permutation_overlap_forest_components;

const usz MAX_N = 8;
const usz MAX_VERTICES = 2 * MAX_N + 2;
const usz MAX_CYCLES = MAX_N + 1;
const usz MAX_INPUT = MAX_N + 2;
const usz MAX_OUTPUT_WORDS = 1 + 3 * MAX_CYCLES;
const usz MAX_OUTPUT = 8 * MAX_OUTPUT_WORDS;

fn void store_word(char* bytes, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        bytes[word * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long signed_permutation_overlap_forest_components(long* input, usz length,
        char* output, usz capacity) @export("signed_permutation_overlap_forest_components") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != (usz)(n_value + 1)) return -1;
    usz n = (usz)n_value, vertex_count = 2 * n + 2;
    long[MAX_VERTICES] permutation = zeroed;
    permutation[vertex_count - 1] = (long)(vertex_count - 1);
    ulong seen = 0;
    for (usz position = 0; position < n; position += 1) {
        long gene = input[position + 1];
        if (gene == 0 || gene < -n_value || gene > n_value) return -1;
        usz absolute = (usz)(gene < 0 ? -gene : gene);
        ulong bit = 1UL << (absolute - 1);
        if ((seen & bit) != 0) return -1;
        seen |= bit;
        usz left = 2 * absolute - 1, right = 2 * absolute;
        if (gene < 0) { usz temporary = left; left = right; right = temporary; }
        permutation[2 * position + 1] = (long)left;
        permutation[2 * position + 2] = (long)right;
    }
    usz[MAX_VERTICES] gray = zeroed;
    for (usz pair = 0; pair <= n; pair += 1) {
        usz left = (usz)permutation[2 * pair], right = (usz)permutation[2 * pair + 1];
        gray[left] = right;
        gray[right] = left;
    }
    long[MAX_VERTICES] cycle_of = zeroed;
    for (usz vertex = 0; vertex < MAX_VERTICES; vertex += 1) cycle_of[vertex] = -1;
    usz[MAX_CYCLES] begin = zeroed, end = zeroed;
    usz cycle_count = 0;
    for (usz seed = 0; seed < vertex_count; seed += 1) {
        if (cycle_of[seed] >= 0) continue;
        usz cid = cycle_count;
        cycle_count += 1;
        usz vertex = seed, low = seed, high = seed;
        while (cycle_of[vertex] < 0) {
            cycle_of[vertex] = (long)cid;
            if (vertex < low) low = vertex;
            if (vertex > high) high = vertex;
            vertex = gray[vertex ^ 1];
        }
        begin[cid] = low;
        end[cid] = high;
    }
    usz[MAX_CYCLES] parent = zeroed;
    for (usz cid = 0; cid < cycle_count; cid += 1) parent[cid] = cid;
    usz[MAX_CYCLES] stack_id = zeroed, stack_begin = zeroed, stack_end = zeroed;
    usz top = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
        usz cid = (usz)cycle_of[vertex], low = begin[cid], high = end[cid];
        if (vertex == low) {
            stack_id[top] = cid; stack_begin[top] = low; stack_end[top] = high; top += 1;
        }
        usz extent_begin = low, extent_end = high;
        while (top > 0 && stack_begin[top - 1] > low) {
            top -= 1;
            usz popped = stack_id[top];
            if (stack_begin[top] < extent_begin) extent_begin = stack_begin[top];
            if (stack_end[top] > extent_end) extent_end = stack_end[top];
            parent[popped] = cid;
        }
        if (top == 0) return -1;
        if (extent_begin < stack_begin[top - 1]) stack_begin[top - 1] = extent_begin;
        if (extent_end > stack_end[top - 1]) stack_end[top - 1] = extent_end;
        if (vertex == stack_end[top - 1]) top -= 1;
    }
    usz[MAX_CYCLES] component = zeroed;
    for (usz cid = 0; cid < cycle_count; cid += 1)
        component[cid] = parent[cid] == cid ? begin[cid] : component[parent[cid]];
    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = (long)cycle_count;
    for (usz cid = 0; cid < cycle_count; cid += 1) {
        words[1 + 3 * cid] = (long)begin[cid];
        words[2 + 3 * cid] = (long)end[cid];
        words[3 + 3 * cid] = (long)component[cid];
    }
    usz output_bytes = (1 + 3 * cycle_count) * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz word = 0; word < 1 + 3 * cycle_count; word += 1)
        store_word(&staged[0], word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
