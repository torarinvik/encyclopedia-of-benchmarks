#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 256;

std::uint32_t spread_16(std::uint32_t value) {
    value = (value | (value << 8)) & UINT32_C(0x00ff00ff);
    value = (value | (value << 4)) & UINT32_C(0x0f0f0f0f);
    value = (value | (value << 2)) & UINT32_C(0x33333333);
    return (value | (value << 1)) & UINT32_C(0x55555555);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t morton_sort(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_points)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;
    std::uint32_t keys[max_points];
    std::size_t order[max_points];
    for (std::size_t index = 0; index < count; ++index) {
        const auto x = input[1 + 2 * index], y = input[2 + 2 * index];
        if (x < 0 || x > 65535 || y < 0 || y > 65535) return -1;
        keys[index] = spread_16(static_cast<std::uint32_t>(x)) |
                      (spread_16(static_cast<std::uint32_t>(y)) << 1);
        order[index] = index;
    }
    const std::size_t bytes = count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t index = 1; index < count; ++index) {
        const auto current = order[index];
        std::size_t position = index;
        while (position > 0 &&
               (keys[order[position - 1]] > keys[current] ||
                (keys[order[position - 1]] == keys[current] && order[position - 1] > current))) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    for (std::size_t index = 0; index < count; ++index) store_i64_le(output, index * 8, static_cast<std::int64_t>(order[index]));
    return static_cast<std::int64_t>(bytes);
}
