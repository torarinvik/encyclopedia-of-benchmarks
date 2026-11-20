module freivalds_matrix_product_verification;
const usz MAX_N = 8; const usz MAX_ROUNDS = 8; const usz MAX_INPUT = 259;

fn long freivalds_matrix_product_verification(long* input, usz length)
    @export("freivalds_matrix_product_verification") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], rounds0 = input[1];
    if (n0 < 1 || n0 > 8 || rounds0 < 1 || rounds0 > 8) return -1;
    usz n = (usz)n0, rounds = (usz)rounds0, matrix_words = n * n;
    if (length != 2 + 3 * matrix_words + rounds * n) return -1;
    for (usz word = 2; word < 2 + 3 * matrix_words; word += 1)
        if (input[word] < -3 || input[word] > 3) return -1;
    usz signs_offset = 2 + 3 * matrix_words;
    for (usz word = signs_offset; word < length; word += 1)
        if (input[word] != -1 && input[word] != 1) return -1;

    long[MAX_N] bx = zeroed;
    long[MAX_N] abx = zeroed;
    long[MAX_N] cx = zeroed;
    for (usz round = 0; round < rounds; round += 1) {
        for (usz row = 0; row < n; row += 1) {
            long sum = 0;
            for (usz col = 0; col < n; col += 1)
                sum += input[2 + matrix_words + row * n + col]
                     * input[signs_offset + round * n + col];
            bx[row] = sum;
        }
        for (usz row = 0; row < n; row += 1) {
            long left = 0, right = 0;
            for (usz col = 0; col < n; col += 1) {
                left += input[2 + row * n + col] * bx[col];
                right += input[2 + 2 * matrix_words + row * n + col]
                       * input[signs_offset + round * n + col];
            }
            abx[row] = left;
            cx[row] = right;
        }
        for (usz row = 0; row < n; row += 1)
            if (abx[row] != cx[row]) return 0;
    }
    return 1;
}
