#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t first_fit_decreasing_bin_packing(const std::int64_t *input, std::size_t length,
                                                           std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 65) return -1;
    const auto n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + static_cast<std::size_t>(n0)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    std::size_t order[64];
    std::int64_t loads[64] = {}, assignments[64] = {};
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i]; auto j = i;
        while (j > 0 && input[order[j - 1] + 1] < input[key + 1]) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    std::size_t bins = 0;
    for (std::size_t pos = 0; pos < n; ++pos) {
        const auto item = order[pos]; const auto size = input[item + 1];
        std::size_t selected = 0;
        while (selected < bins && loads[selected] + size > 1000000) ++selected;
        if (selected == bins) { loads[bins] = size; assignments[item] = static_cast<std::int64_t>(bins++); }
        else { loads[selected] += size; assignments[item] = static_cast<std::int64_t>(selected); }
    }
    const auto bytes = 8 * (n + 1);
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, static_cast<std::int64_t>(bins));
    for (std::size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignments[i]);
    return static_cast<std::int64_t>(bytes);
}
