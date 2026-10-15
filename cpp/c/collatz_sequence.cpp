#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_START = 1'000'000;

std::int64_t next_term(std::int64_t value)
{
    return value % 2 == 0 ? value / 2 : 3 * value + 1;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t collatz_sequence(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length != 1 || input[0] < 1 || input[0] > MAX_START) return -1;
    auto current = input[0];
    std::size_t term_count = 1;
    while (current != 1) { current = next_term(current); ++term_count; }
    const std::size_t required = term_count * 8;
    if (output_capacity < required || output == nullptr) return -2;
    current = input[0];
    std::size_t written = 0;
    for (;;) {
        store_i64_le(output, written, current);
        written += 8;
        if (current == 1) break;
        current = next_term(current);
    }
    return static_cast<std::int64_t>(written);
}
