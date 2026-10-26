/* Clean-room, bounded BEEBS FASTA generation profile. */
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t FASTA_MAX_COUNT = 1000;
constexpr std::int64_t FASTA_MAX_STATE = 139967;
constexpr std::uint32_t FASTA_MODULUS = 139968U;
constexpr std::size_t FASTA_WIDTH = 60;
constexpr char ALU[] =
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";
constexpr float IUB_WEIGHTS[15] = {
    0.27f, 0.12f, 0.12f, 0.27f, 0.02f, 0.02f, 0.02f, 0.02f,
    0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f
};
constexpr std::uint8_t IUB_SYMBOLS[15] = {
    'a', 'c', 'g', 't', 'B', 'D', 'H', 'K', 'M', 'N', 'R', 'S', 'V', 'W', 'Y'
};
constexpr float HUMAN_WEIGHTS[4] = {
    0.3029549426680f, 0.1979883004921f, 0.1975473066391f, 0.3015094502008f
};
constexpr std::uint8_t HUMAN_SYMBOLS[4] = {'a', 'c', 'g', 't'};

std::size_t wrapped_lines(std::size_t count) noexcept {
    return (count + FASTA_WIDTH - 1) / FASTA_WIDTH;
}

std::size_t output_length(std::size_t count) noexcept {
    return 77 + 10 * count + wrapped_lines(2 * count)
        + wrapped_lines(3 * count) + wrapped_lines(5 * count);
}

void accumulate_probabilities(float *weights, std::size_t size) noexcept {
    float cumulative = 0.0f;
    for (std::size_t i = 0; i < size; ++i) {
        cumulative += weights[i];
        weights[i] = cumulative;
    }
}

std::uint8_t next_weighted_base(std::uint32_t &state, const float *weights,
                                const std::uint8_t *symbols, std::size_t size) noexcept {
    state = (state * 3877U + 29573U) % FASTA_MODULUS;
    const float random_value = 1.0f * static_cast<float>(state) / static_cast<float>(FASTA_MODULUS);
    for (std::size_t i = 0; i < size; ++i) {
        if (weights[i] >= random_value) return symbols[i];
    }
    return symbols[size - 1];
}

std::size_t write_repeat(std::uint8_t *output, std::size_t offset,
                         std::size_t count) noexcept {
    constexpr std::size_t sequence_length = sizeof(ALU) - 1;
    for (std::size_t i = 0; i < count; ++i) {
        output[offset++] = static_cast<std::uint8_t>(ALU[i % sequence_length]);
        if ((i + 1) % FASTA_WIDTH == 0 || i + 1 == count) output[offset++] = '\n';
    }
    return offset;
}

std::size_t write_weighted(std::uint8_t *output, std::size_t offset,
                           std::size_t count, std::uint32_t &state,
                           const float *weights, const std::uint8_t *symbols,
                           std::size_t size) noexcept {
    for (std::size_t i = 0; i < count; ++i) {
        output[offset++] = next_weighted_base(state, weights, symbols, size);
        if ((i + 1) % FASTA_WIDTH == 0 || i + 1 == count) output[offset++] = '\n';
    }
    return offset;
}
}

extern "C" std::int64_t beebs_fasta(const std::int64_t *values, std::size_t length,
                                     std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const auto count_value = values[0];
    const auto seed_value = values[1];
    if (count_value < 1 || count_value > FASTA_MAX_COUNT
        || seed_value < 0 || seed_value > FASTA_MAX_STATE) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    const auto needed = output_length(count);
    if (output == nullptr || capacity < needed) return -2;
    float iub_weights[15], human_weights[4];
    std::memcpy(iub_weights, IUB_WEIGHTS, sizeof(iub_weights));
    std::memcpy(human_weights, HUMAN_WEIGHTS, sizeof(human_weights));
    accumulate_probabilities(iub_weights, 15);
    accumulate_probabilities(human_weights, 4);

    std::size_t offset = 0;
    constexpr char header_one[] = ">ONE Homo sapiens alu\n";
    constexpr char header_two[] = ">TWO IUB ambiguity codes\n";
    constexpr char header_three[] = ">THREE Homo sapiens frequency\n";
    std::memcpy(output + offset, header_one, sizeof(header_one) - 1); offset += sizeof(header_one) - 1;
    offset = write_repeat(output, offset, 2 * count);
    std::memcpy(output + offset, header_two, sizeof(header_two) - 1); offset += sizeof(header_two) - 1;
    std::uint32_t state = static_cast<std::uint32_t>(seed_value);
    offset = write_weighted(output, offset, 3 * count, state, iub_weights, IUB_SYMBOLS, 15);
    std::memcpy(output + offset, header_three, sizeof(header_three) - 1); offset += sizeof(header_three) - 1;
    offset = write_weighted(output, offset, 5 * count, state, human_weights, HUMAN_SYMBOLS, 4);
    return static_cast<std::int64_t>(offset);
}
