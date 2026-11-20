#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t bits = 32;
constexpr std::size_t max_hash_bits = 16;
constexpr std::size_t max_queries = 32;
constexpr std::uint64_t word_mask = 0xffff'ffffULL;

void write_u64_le(std::uint8_t *output, std::size_t query, std::uint64_t value)
{
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[query * 8 + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t multiply_shift_universal_hash_trace(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity)
{
    if (input == nullptr || length < 2 || length > 2 + 2 * max_queries + 1) return -1;
    const std::int64_t width_value = input[0];
    const std::int64_t count_value = input[1];
    if (width_value < 1 || width_value > static_cast<std::int64_t>(max_hash_bits) ||
        count_value < 0 || count_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * count) return -1;

    for (std::size_t query = 0; query < count; ++query) {
        const std::int64_t multiplier = input[2 + 2 * query];
        const std::int64_t key = input[3 + 2 * query];
        if (multiplier < 1 || multiplier > static_cast<std::int64_t>(word_mask) ||
            (multiplier & 1) == 0 || key < 0 || key > static_cast<std::int64_t>(word_mask))
            return -1;
    }

    const std::size_t required = count * 8;
    if ((required > 0 && output == nullptr) || capacity < required) return -2;
    const unsigned shift = static_cast<unsigned>(bits - static_cast<std::size_t>(width_value));
    for (std::size_t query = 0; query < count; ++query) {
        const auto multiplier = static_cast<std::uint64_t>(input[2 + 2 * query]);
        const auto key = static_cast<std::uint64_t>(input[3 + 2 * query]);
        const std::uint64_t low_word = (multiplier * key) & word_mask;
        write_u64_le(output, query, low_word >> shift);
    }
    return static_cast<std::int64_t>(required);
}
