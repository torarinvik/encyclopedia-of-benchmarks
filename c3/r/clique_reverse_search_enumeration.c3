module clique_reverse_search_enumeration;

const usz MAX_N = 8;
const usz MAX_INPUT = 9;
const usz MAX_CLIQUES = 256;
const usz MAX_OUTPUT_BYTES = 264;

fn void visit(usz n, ulong* adjacency, ulong clique, char* masks, usz* count) {
    masks[(*count)++] = (char)clique;
    usz minimum = n;
    for (usz vertex = 0; vertex < n; vertex++) {
        if ((clique & (1UL << vertex)) != 0) { minimum = vertex; break; }
    }
    for (usz vertex = 0; vertex < minimum; vertex++) {
        ulong bit = 1UL << vertex;
        if ((clique & bit) == 0 && (adjacency[vertex] & clique) == clique)
            visit(n, adjacency, clique | bit, masks, count);
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long clique_reverse_search_enumeration(long* input, usz length, char* output, usz capacity)
    @export("clique_reverse_search_enumeration") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    ulong[MAX_N] adjacency;
    for (usz vertex = 0; vertex < n; vertex++) {
        long raw = input[vertex + 1];
        if (raw < 0 || (ulong)raw >= (1UL << n) || ((ulong)raw & (1UL << vertex)) != 0) return -1;
        adjacency[vertex] = (ulong)raw;
    }
    for (usz left = 0; left < n; left++) {
        for (usz right = left + 1; right < n; right++) {
            bool edge_left = (adjacency[left] & (1UL << right)) != 0;
            bool edge_right = (adjacency[right] & (1UL << left)) != 0;
            if (edge_left != edge_right) return -1;
        }
    }
    char[MAX_CLIQUES] masks;
    usz count = 0;
    visit(n, &adjacency[0], 0, &masks[0], &count);
    usz required = 8 + count;
    if (output == null || capacity < required) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, (long)count);
    for (usz index = 0; index < count; index++) staged[8 + index] = masks[index];
    for (usz byte = 0; byte < required; byte++) output[byte] = staged[byte];
    return (long)required;
}
