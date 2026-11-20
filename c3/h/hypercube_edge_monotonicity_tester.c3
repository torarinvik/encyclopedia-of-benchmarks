module hypercube_edge_monotonicity_tester;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long hypercube_edge_monotonicity_tester(long* input, usz length, char* output,
        usz capacity) @export("hypercube_edge_monotonicity_tester") {
    if (input == null || length < 2 || length > 130) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 6 || q_value < 1 || q_value > 32) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    usz domain = (usz)1 << n;
    if (length != 2 + domain + 2 * q) return -1;
    for (usz vertex = 0; vertex < domain; vertex++)
        if (input[2 + vertex] != 0 && input[2 + vertex] != 1) return -1;
    usz tape = 2 + domain;
    for (usz round = 0; round < q; round++) {
        long vertex = input[tape + 2 * round], coordinate = input[tape + 2 * round + 1];
        if (vertex < 0 || (ulong)vertex >= domain || coordinate < 0 || (ulong)coordinate >= n) return -1;
    }
    long accepted = 1, rounds = 0;
    for (usz round = 0; round < q; round++) {
        usz vertex = (usz)input[tape + 2 * round];
        usz bit = (usz)1 << (usz)input[tape + 2 * round + 1];
        usz lower = vertex & ~bit;
        rounds++;
        if (input[2 + lower] > input[2 + (lower | bit)]) { accepted = 0; break; }
    }
    if (output == null || capacity < 24) return -2;
    store_i64_le(output, 0, accepted);
    store_i64_le(output, 8, rounds);
    store_i64_le(output, 16, 2 * rounds);
    return 24;
}
