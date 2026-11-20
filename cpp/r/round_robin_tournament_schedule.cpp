#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxTeams = 8;
constexpr std::size_t kMaxParseableInput = 2;
constexpr std::size_t kMaxCells = 64;
}

extern "C" std::int64_t round_robin_tournament_schedule(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxParseableInput) return -1;
    if (length != 1) return -1;
    const std::int64_t n_word = input[0];
    if (n_word < 2 || n_word > static_cast<std::int64_t>(kMaxTeams)) return -1;

    const std::size_t n = static_cast<std::size_t>(n_word);
    const std::size_t padded = n + (n & 1U);
    const std::size_t ring_size = padded - 1;
    const std::size_t rounds = ring_size;
    const std::size_t fixed = padded - 1;
    std::uint8_t table[kMaxCells];
    for (std::size_t i = 0; i < kMaxCells; ++i) table[i] = UINT8_MAX;

    for (std::size_t round = 0; round < rounds; ++round) {
        if (fixed < n) {
            table[fixed * rounds + round] = static_cast<std::uint8_t>(round);
            table[round * rounds + round] = static_cast<std::uint8_t>(fixed);
        }
        for (std::size_t offset = 1; offset < padded / 2; ++offset) {
            const std::size_t left = (round + offset) % ring_size;
            const std::size_t right = (round + ring_size - offset) % ring_size;
            if (left < n && right < n) {
                table[left * rounds + round] = static_cast<std::uint8_t>(right);
                table[right * rounds + round] = static_cast<std::uint8_t>(left);
            }
        }
    }

    const std::size_t required = 2 + n * rounds;
    if (output == nullptr || capacity < required) return -2;
    output[0] = static_cast<std::uint8_t>(n);
    output[1] = static_cast<std::uint8_t>(rounds);
    for (std::size_t i = 0; i < n * rounds; ++i) output[2 + i] = table[i];
    return static_cast<std::int64_t>(required);
}
