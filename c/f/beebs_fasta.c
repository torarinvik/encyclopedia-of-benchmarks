/* Clean-room, bounded BEEBS FASTA generation profile. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define FASTA_MAX_COUNT 1000
#define FASTA_MAX_STATE 139967
#define FASTA_MODULUS 139968U
#define FASTA_MAX_OUTPUT 10245
#define FASTA_WIDTH 60

static const uint8_t ALU[] =
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";
static const float IUB_WEIGHTS[15] = {
    0.27f, 0.12f, 0.12f, 0.27f, 0.02f, 0.02f, 0.02f, 0.02f,
    0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f
};
static const uint8_t IUB_SYMBOLS[15] = {
    'a', 'c', 'g', 't', 'B', 'D', 'H', 'K', 'M', 'N', 'R', 'S', 'V', 'W', 'Y'
};
static const float HUMAN_WEIGHTS[4] = {
    0.3029549426680f, 0.1979883004921f, 0.1975473066391f, 0.3015094502008f
};
static const uint8_t HUMAN_SYMBOLS[4] = {'a', 'c', 'g', 't'};

static size_t wrapped_lines(size_t count) {
    return (count + FASTA_WIDTH - 1) / FASTA_WIDTH;
}

static size_t fasta_output_length(size_t count) {
    return 77 + 10 * count + wrapped_lines(2 * count)
        + wrapped_lines(3 * count) + wrapped_lines(5 * count);
}

static void accumulate_probabilities(float *weights, size_t size) {
    float cumulative = 0.0f;
    for (size_t i = 0; i < size; ++i) {
        cumulative += weights[i];
        weights[i] = cumulative;
    }
}

static uint8_t next_weighted_base(uint32_t *state, const float *weights,
                                  const uint8_t *symbols, size_t size) {
    *state = (*state * 3877U + 29573U) % FASTA_MODULUS;
    const float random_value = 1.0f * (float)*state / (float)FASTA_MODULUS;
    for (size_t i = 0; i < size; ++i) {
        if (weights[i] >= random_value) return symbols[i];
    }
    return symbols[size - 1];
}

static size_t write_repeat(uint8_t *output, size_t offset, size_t count) {
    const size_t sequence_length = sizeof(ALU) - 1;
    for (size_t i = 0; i < count; ++i) {
        output[offset++] = ALU[i % sequence_length];
        if ((i + 1) % FASTA_WIDTH == 0 || i + 1 == count) output[offset++] = '\n';
    }
    return offset;
}

static size_t write_weighted(uint8_t *output, size_t offset, size_t count,
                             uint32_t *state, const float *weights,
                             const uint8_t *symbols, size_t size) {
    for (size_t i = 0; i < count; ++i) {
        output[offset++] = next_weighted_base(state, weights, symbols, size);
        if ((i + 1) % FASTA_WIDTH == 0 || i + 1 == count) output[offset++] = '\n';
    }
    return offset;
}

int64_t beebs_fasta(const int64_t *values, size_t length,
                    uint8_t *output, size_t capacity) {
    if (values == NULL || length != 2) return -1;
    const int64_t count_value = values[0];
    const int64_t seed_value = values[1];
    if (count_value < 1 || count_value > FASTA_MAX_COUNT
        || seed_value < 0 || seed_value > FASTA_MAX_STATE) return -1;
    const size_t count = (size_t)count_value;
    const size_t output_length = fasta_output_length(count);
    if (output == NULL || capacity < output_length) return -2;
    float iub_weights[15], human_weights[4];
    memcpy(iub_weights, IUB_WEIGHTS, sizeof(iub_weights));
    memcpy(human_weights, HUMAN_WEIGHTS, sizeof(human_weights));
    accumulate_probabilities(iub_weights, 15);
    accumulate_probabilities(human_weights, 4);

    size_t offset = 0;
    static const char header_one[] = ">ONE Homo sapiens alu\n";
    static const char header_two[] = ">TWO IUB ambiguity codes\n";
    static const char header_three[] = ">THREE Homo sapiens frequency\n";
    memcpy(output + offset, header_one, sizeof(header_one) - 1); offset += sizeof(header_one) - 1;
    offset = write_repeat(output, offset, 2 * count);
    memcpy(output + offset, header_two, sizeof(header_two) - 1); offset += sizeof(header_two) - 1;
    uint32_t state = (uint32_t)seed_value;
    offset = write_weighted(output, offset, 3 * count, &state, iub_weights,
                            IUB_SYMBOLS, 15);
    memcpy(output + offset, header_three, sizeof(header_three) - 1); offset += sizeof(header_three) - 1;
    offset = write_weighted(output, offset, 5 * count, &state, human_weights,
                            HUMAN_SYMBOLS, 4);
    return (int64_t)offset;
}
