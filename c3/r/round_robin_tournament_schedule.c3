const MAX_TEAMS = 8;
const MAX_PARSEABLE_INPUT = 2;
const MAX_CELLS = 64;

long round_robin_tournament_schedule(long* input, usz length, char* output, usz capacity)
    @export("round_robin_tournament_schedule") {
    if (input == null || length == 0 || length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1) return -1;
    long n_word = input[0];
    if (n_word < 2 || n_word > MAX_TEAMS) return -1;

    usz n = (usz)n_word;
    usz padded = n + (n & 1);
    usz ring_size = padded - 1;
    usz rounds = ring_size;
    usz fixed = padded - 1;
    char[MAX_CELLS] table = {};
    for (usz i = 0; i < MAX_CELLS; i++) table[i] = (char)255;

    for (usz round = 0; round < rounds; round++) {
        if (fixed < n) {
            table[fixed * rounds + round] = (char)round;
            table[round * rounds + round] = (char)fixed;
        }
        for (usz offset = 1; offset < padded / 2; offset++) {
            usz left = (round + offset) % ring_size;
            usz right = (round + ring_size - offset) % ring_size;
            if (left < n && right < n) {
                table[left * rounds + round] = (char)right;
                table[right * rounds + round] = (char)left;
            }
        }
    }

    usz required = 2 + n * rounds;
    if (output == null || capacity < required) return -2;
    output[0] = (char)n;
    output[1] = (char)rounds;
    for (usz i = 0; i < n * rounds; i++) output[2 + i] = table[i];
    return (long)required;
}
