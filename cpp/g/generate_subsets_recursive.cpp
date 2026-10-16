#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 12;
void put32(std::uint8_t *out, std::size_t &pos, std::uint32_t value)
{
    for (int i = 0; i < 4; ++i) { out[pos++] = static_cast<std::uint8_t>(value); value >>= 8; }
}
void emit_subsets(const std::int64_t *input, std::size_t n, std::size_t index,
                  std::uint32_t mask, std::uint32_t selected, std::uint8_t *out, std::size_t &pos)
{
    if (index == n) {
        put32(out, pos, selected);
        for (std::size_t i = 0; i < n; ++i)
            if ((mask & (std::uint32_t{1} << i)) != 0) out[pos++] = static_cast<std::uint8_t>(input[i + 1]);
        return;
    }
    emit_subsets(input, n, index + 1, mask | (std::uint32_t{1} << index), selected + 1, out, pos);
    emit_subsets(input, n, index + 1, mask, selected, out, pos);
}
}

extern "C" std::int64_t generate_subsets_recursive(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (!input || length < 1 || length > max_items + 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_items)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    const std::size_t subsets = std::size_t{1} << n;
    const std::size_t needed = 4 + 4 * subsets + n * (subsets / 2);
    if (!output || capacity < needed) return -2;
    std::size_t pos = 0;
    put32(output, pos, static_cast<std::uint32_t>(subsets));
    emit_subsets(input, n, 0, 0, 0, output, pos);
    return static_cast<std::int64_t>(pos);
}
