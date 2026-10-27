module reverse_search_permutation_enumeration;

const usz MAX_N = 4;
const usz MAX_INPUT = 2;
const usz MAX_WORDS = 97;

fn void visit(long* permutation, usz n, long* staged, usz* cursor) {
    for (usz index = 0; index < n; index++) staged[(*cursor)++] = permutation[index];
    usz reverse_point = n;
    for (usz index = 0; index + 1 < n; index++) {
        if (permutation[index] > permutation[index + 1]) { reverse_point = index + 1; break; }
    }
    for (usz child = 1; child < reverse_point; child++) {
        long temporary = permutation[child - 1];
        permutation[child - 1] = permutation[child];
        permutation[child] = temporary;
        visit(permutation, n, staged, cursor);
        temporary = permutation[child - 1];
        permutation[child - 1] = permutation[child];
        permutation[child] = temporary;
    }
    if (reverse_point + 2 <= n && permutation[reverse_point - 1] < permutation[reverse_point + 1]) {
        usz left = reverse_point;
        long temporary = permutation[left];
        permutation[left] = permutation[left + 1];
        permutation[left + 1] = temporary;
        visit(permutation, n, staged, cursor);
        temporary = permutation[left];
        permutation[left] = permutation[left + 1];
        permutation[left + 1] = temporary;
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long reverse_search_permutation_enumeration(long* input, usz length, char* output, usz capacity)
    @export("reverse_search_permutation_enumeration") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    if (length != 1 || input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz count = 1;
    for (usz factor = 2; factor <= n; factor++) count *= factor;
    usz words = 1 + n * count;
    usz required = words * 8;
    if (output == null || capacity < required) return -2;

    long[MAX_N] permutation;
    long[MAX_WORDS] staged;
    for (usz index = 0; index < n; index++) permutation[index] = (long)index + 1;
    staged[0] = (long)count;
    usz cursor = 1;
    visit(&permutation[0], n, &staged[0], &cursor);
    for (usz word = 0; word < words; word++) store_i64_le(output, word * 8, staged[word]);
    return (long)required;
}
