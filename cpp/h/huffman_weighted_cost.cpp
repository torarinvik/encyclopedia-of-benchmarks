#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_symbols = 26;
constexpr std::int64_t max_total_frequency = 2147483647;

void store_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t huffman_weighted_cost(const std::int64_t *values, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 1 || length > 1 + 2 * max_symbols) return -1;
    const auto raw_count = values[0];
    if (raw_count < 2 || raw_count > static_cast<std::int64_t>(max_symbols)
        || length != 1 + 2 * static_cast<std::size_t>(raw_count)) return -1;

    const auto count = static_cast<std::size_t>(raw_count);
    bool seen[max_symbols] = {};
    bool active[max_symbols] = {};
    std::int64_t weights[max_symbols] = {};
    std::int64_t total = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto symbol = values[1 + 2 * index];
        const auto frequency = values[2 + 2 * index];
        if (symbol < 'a' || symbol > 'z' || frequency < 1 || frequency > max_total_frequency) return -1;
        const auto letter = static_cast<std::size_t>(symbol - 'a');
        if (seen[letter] || total > max_total_frequency - frequency) return -1;
        seen[letter] = true;
        active[index] = true;
        weights[index] = frequency;
        total += frequency;
    }

    auto remaining = count;
    std::int64_t cost = 0;
    while (remaining > 1) {
        std::size_t first = max_symbols, second = max_symbols;
        for (std::size_t index = 0; index < count; ++index) {
            if (!active[index]) continue;
            if (first == max_symbols || weights[index] < weights[first]) {
                second = first;
                first = index;
            } else if (second == max_symbols || weights[index] < weights[second]) {
                second = index;
            }
        }
        weights[first] += weights[second];
        active[second] = false;
        cost += weights[first];
        --remaining;
    }

    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, cost);
    return cost;
}
