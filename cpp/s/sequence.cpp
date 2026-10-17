#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_count = 64;
constexpr std::size_t max_parseable_input_length = 3;
constexpr std::size_t max_output_bytes = 8 * 64;

std::int64_t generate_nth_term(std::int64_t index)
{
    if (index == 0 || index == 1) return index;
    if (index % 2 == 0) return 4 * generate_nth_term(index / 2);
    return 4 * generate_nth_term(index / 2) + 1;
}

void put_i64_le(std::int64_t value, std::uint8_t *output, std::size_t offset)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t sequence(const std::int64_t *values, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    if (length != 1 || values[0] < -max_count || values[0] > max_count) return -1;
    if (values[0] <= 0) return 0;

    const auto count = static_cast<std::size_t>(values[0]);
    const auto required = count * 8;
    if (output == nullptr || output_capacity < required || required > max_output_bytes) return -2;
    for (std::size_t index = 0; index < count; ++index)
        put_i64_le(generate_nth_term(static_cast<std::int64_t>(index)), output, index * 8);
    return static_cast<std::int64_t>(required);
}
