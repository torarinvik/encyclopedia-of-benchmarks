module beebs_fasta;

const long MAX_COUNT = 1000;
const long MAX_STATE = 139967;
const usz WIDTH = 60;
const char[] ALU =
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";
const float[15] IUB_WEIGHTS = {0.27f,0.12f,0.12f,0.27f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f,0.02f};
const char[15] IUB_SYMBOLS = "acgtBDHKMNRSVWY";
const float[4] HUMAN_WEIGHTS = {0.3029549426680f,0.1979883004921f,0.1975473066391f,0.3015094502008f};
const char[4] HUMAN_SYMBOLS = "acgt";

fn usz wrapped_lines(usz count) { return (count + WIDTH - 1) / WIDTH; }
fn usz fasta_output_length(usz count) {
    return 77 + 10 * count + wrapped_lines(2 * count) + wrapped_lines(3 * count) + wrapped_lines(5 * count);
}

fn void accumulate_probabilities(float* weights, usz size) {
    float cumulative = 0.0f;
    for (usz i = 0; i < size; i++) { cumulative += weights[i]; weights[i] = cumulative; }
}

fn uchar next_weighted_base(long* state, const float* weights, const char* symbols, usz size) {
    state[0] = (state[0] * 3877 + 29573) % 139968;
    float random_value = 1.0f * state[0].float() / 139968.0f;
    for (usz i = 0; i < size; i++) {
        if (weights[i] >= random_value) return (uchar)symbols[i];
    }
    return (uchar)symbols[size - 1];
}

fn usz write_repeat(uchar* output, usz offset, usz count) {
    for (usz i = 0; i < count; i++) {
        output[offset++] = (uchar)ALU[i % ALU.len];
        if ((i + 1) % WIDTH == 0 || i + 1 == count) output[offset++] = 10;
    }
    return offset;
}

fn usz write_weighted(uchar* output, usz offset, usz count, long* state,
                      const float* weights, const char* symbols, usz size) {
    for (usz i = 0; i < count; i++) {
        output[offset++] = next_weighted_base(state, weights, symbols, size);
        if ((i + 1) % WIDTH == 0 || i + 1 == count) output[offset++] = 10;
    }
    return offset;
}

fn long beebs_fasta(long* values, usz length, uchar* output, usz capacity) @export("beebs_fasta") {
    if (values == null || length != 2) return -1;
    long count_value = values[0];
    long seed_value = values[1];
    if (count_value < 1 || count_value > MAX_COUNT || seed_value < 0 || seed_value > MAX_STATE) return -1;
    usz count = (usz)count_value;
    usz needed = fasta_output_length(count);
    if (output == null || capacity < needed) return -2;
    float[15] iub_weights;
    float[4] human_weights;
    for (usz i = 0; i < 15; i++) iub_weights[i] = IUB_WEIGHTS[i];
    for (usz i = 0; i < 4; i++) human_weights[i] = HUMAN_WEIGHTS[i];
    accumulate_probabilities(&iub_weights[0], 15);
    accumulate_probabilities(&human_weights[0], 4);

    const char* header_one = ">ONE Homo sapiens alu\n";
    const char* header_two = ">TWO IUB ambiguity codes\n";
    const char* header_three = ">THREE Homo sapiens frequency\n";
    usz offset = 0;
    for (usz i = 0; i < 22; i++) output[offset++] = (uchar)header_one[i];
    offset = write_repeat(output, offset, 2 * count);
    for (usz i = 0; i < 25; i++) output[offset++] = (uchar)header_two[i];
    long state = seed_value;
    offset = write_weighted(output, offset, 3 * count, &state, &iub_weights[0], IUB_SYMBOLS, 15);
    for (usz i = 0; i < 30; i++) output[offset++] = (uchar)header_three[i];
    offset = write_weighted(output, offset, 5 * count, &state, &human_weights[0], HUMAN_SYMBOLS, 4);
    return (long)offset;
}
