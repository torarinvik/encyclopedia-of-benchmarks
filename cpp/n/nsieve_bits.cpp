#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 1'000'000;
constexpr std::size_t max_words = 15626;

std::int64_t count_primes(std::int64_t limit) {
    std::array<std::uint64_t, max_words> bits{};
    bits.fill(UINT64_MAX);
    std::int64_t count = 0;
    for (std::int64_t value = 2; value <= limit; ++value) {
        const auto word = static_cast<std::size_t>(value >> 6);
        const auto mask = std::uint64_t{1} << (value & 63);
        if ((bits[word] & mask) != 0) {
            ++count;
            for (auto multiple = value + value; multiple <= limit; multiple += value) {
                const auto multiple_word = static_cast<std::size_t>(multiple >> 6);
                const auto multiple_mask = std::uint64_t{1} << (multiple & 63);
                if ((bits[multiple_word] & multiple_mask) != 0) bits[multiple_word] ^= multiple_mask;
            }
        }
    }
    return count;
}

void put_u64_le(std::uint8_t* output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t benchmarkgame_nsieve_bits(const std::int64_t* input, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length != 1 || input[0] < 0 || input[0] > max_limit) return -1;
    if (output == nullptr || capacity < 24) return -2;
    for (std::size_t pass = 0; pass < 3; ++pass)
        put_u64_le(output, pass * 8, static_cast<std::uint64_t>(count_primes(input[0] >> pass)));
    return 24;
}
