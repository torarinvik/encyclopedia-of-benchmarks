module gray_code_k_combinations;

fn usz combination_count(usz n, usz k) {
    usz choose = k < n - k ? k : n - k;
    usz count = 1;
    for (usz i = 1; i <= choose; i++) count = count * (n - choose + i) / i;
    return count;
}

fn void write_u16(char* output, usz offset, usz value) {
    output[offset] = (char)(value & 255);
    output[offset + 1] = (char)((value >> 8) & 255);
}

fn long gray_code_k_combinations(long* input, usz length, char* output,
        usz capacity) @export("gray_code_k_combinations") {
    if (input == null || length != 2 || input[0] < 0 || input[0] > 12 ||
        input[1] < 0 || input[1] > input[0]) return -1;
    usz n = (usz)input[0], k = (usz)input[1];
    usz count = combination_count(n, k);
    usz required = 2 + 2 * count;
    if (output == null || capacity < required) return -2;
    write_u16(output, 0, count);

    usz emitted = 0;
    usz limit = (usz)1 << n;
    for (usz index = 0; index < limit; index++) {
        usz mask = index ^ (index >> 1);
        usz bits = mask, population = 0;
        while (bits != 0) { bits &= bits - 1; population++; }
        if (population == k) write_u16(output, 2 + 2 * emitted++, mask);
    }
    return (long)count;
}
