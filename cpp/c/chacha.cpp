#include <cstddef>
#include <cstdint>

namespace {
constexpr int CHACHA_WORDS = 16;
constexpr int CHACHA_BYTES = 64;
constexpr std::uint64_t WORD_MASK = UINT64_C(0xffffffff);

std::uint64_t rotate_left(std::uint64_t value, unsigned int count)
{
    return ((value << count) | (value >> (32 - count))) & WORD_MASK;
}

void quarter_round(std::uint64_t state[CHACHA_WORDS], int a, int b, int c, int d)
{
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = rotate_left(state[d] ^ state[a], 16);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = rotate_left(state[b] ^ state[c], 12);
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = rotate_left(state[d] ^ state[a], 8);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = rotate_left(state[b] ^ state[c], 7);
}
}

extern "C" std::int64_t chacha(const std::int64_t *input, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length != CHACHA_WORDS) return -1;
    std::uint64_t initial[CHACHA_WORDS];
    for (std::size_t index = 0; index < CHACHA_WORDS; ++index) {
        if (input[index] < 0 || static_cast<std::uint64_t>(input[index]) > WORD_MASK) return -1;
        initial[index] = static_cast<std::uint64_t>(input[index]);
    }
    if (output == nullptr || output_capacity < CHACHA_BYTES) return -2;

    std::uint64_t state[CHACHA_WORDS];
    for (int index = 0; index < CHACHA_WORDS; ++index) state[index] = initial[index];
    for (int round = 0; round < 10; ++round) {
        quarter_round(state, 0, 4, 8, 12);
        quarter_round(state, 1, 5, 9, 13);
        quarter_round(state, 2, 6, 10, 14);
        quarter_round(state, 3, 7, 11, 15);
        quarter_round(state, 0, 5, 10, 15);
        quarter_round(state, 1, 6, 11, 12);
        quarter_round(state, 2, 7, 8, 13);
        quarter_round(state, 3, 4, 9, 14);
    }
    for (std::size_t index = 0; index < CHACHA_WORDS; ++index) {
        const std::uint32_t word = static_cast<std::uint32_t>((state[index] + initial[index]) & WORD_MASK);
        output[4 * index] = static_cast<std::uint8_t>(word);
        output[4 * index + 1] = static_cast<std::uint8_t>(word >> 8);
        output[4 * index + 2] = static_cast<std::uint8_t>(word >> 16);
        output[4 * index + 3] = static_cast<std::uint8_t>(word >> 24);
    }
    return CHACHA_BYTES;
}
