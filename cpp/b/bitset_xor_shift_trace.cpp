#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_bits = 4096;
constexpr std::size_t max_words = 64;
constexpr std::size_t max_operations = 64;

std::uint32_t popcount64(std::uint64_t value) {
    std::uint32_t count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

void store_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t bitset_xor_shift_trace(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 3 || length > 131) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_bits)
        || q_value < 0 || q_value > static_cast<std::int64_t>(max_operations)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    const auto word_count = (n + 63) / 64;
    const auto shift_offset = 2 + word_count;
    if (length != shift_offset + q) return -1;

    std::array<std::uint64_t, max_words> words{};
    for (std::size_t word = 0; word < word_count; ++word)
        words[word] = static_cast<std::uint64_t>(input[2 + word]);
    const auto tail_bits = n % 64;
    const auto tail_mask = tail_bits == 0 ? UINT64_MAX : (UINT64_C(1) << tail_bits) - 1;
    if ((words[word_count - 1] & ~tail_mask) != 0) return -1;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto shift = input[shift_offset + operation];
        if (shift < -(n_value - 1) || shift > n_value - 1) return -1;
    }

    const auto output_bytes = q * 4;
    if (output_bytes != 0 && (output == nullptr || output_capacity < output_bytes)) return -2;
    std::array<std::int32_t, max_operations> counts{};
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto shift = input[shift_offset + operation];
        if (shift == 0) {
            for (std::size_t word = 0; word < word_count; ++word) words[word] = 0;
        } else if (shift > 0) {
            const auto distance = static_cast<std::size_t>(shift);
            const auto whole = distance / 64, part = distance % 64;
            for (std::size_t destination = 0; destination < word_count; ++destination) {
                const auto source = destination + whole;
                std::uint64_t shifted = source < word_count ? words[source] >> part : 0;
                if (part != 0 && source + 1 < word_count)
                    shifted |= words[source + 1] << (64 - part);
                words[destination] ^= shifted;
            }
        } else {
            const auto distance = static_cast<std::size_t>(-shift);
            const auto whole = distance / 64, part = distance % 64;
            for (std::size_t destination = word_count; destination > 0; --destination) {
                const auto target = destination - 1;
                const auto source = static_cast<std::ptrdiff_t>(target)
                                  - static_cast<std::ptrdiff_t>(whole);
                std::uint64_t shifted = source >= 0 ? words[static_cast<std::size_t>(source)] << part : 0;
                if (part != 0 && source > 0)
                    shifted |= words[static_cast<std::size_t>(source) - 1] >> (64 - part);
                words[target] ^= shifted;
            }
        }
        words[word_count - 1] &= tail_mask;
        std::uint32_t count = 0;
        for (std::size_t word = 0; word < word_count; ++word) count += popcount64(words[word]);
        counts[operation] = static_cast<std::int32_t>(count);
    }
    for (std::size_t operation = 0; operation < q; ++operation)
        store_i32_le(output, operation * 4, counts[operation]);
    return static_cast<std::int64_t>(output_bytes);
}
