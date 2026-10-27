#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t bounded_space_best_fit_bin_packing(const std::int64_t *input, std::size_t length,
                                                            std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 65) return -1;
    const auto n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + static_cast<std::size_t>(n0)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    std::int64_t loads[64] = {}, assignments[64] = {};
    bool open[64] = {};
    std::size_t bins = 0;
    for (std::size_t item = 0; item < n; ++item) {
        const auto size = input[item + 1];
        std::size_t selected = bins;
        std::int64_t least_remaining = 1000001;
        for (std::size_t bin = 0; bin < bins; ++bin) if (open[bin] && loads[bin] + size <= 1000000) {
            const auto remaining = 1000000 - loads[bin] - size;
            if (remaining < least_remaining) { least_remaining = remaining; selected = bin; }
        }
        if (selected == bins) { loads[bins] = size; open[bins] = size < 1000000; assignments[item] = static_cast<std::int64_t>(bins++); }
        else { loads[selected] += size; assignments[item] = static_cast<std::int64_t>(selected); if (loads[selected] == 1000000) open[selected] = false; }
        std::size_t partial_open = 0;
        for (std::size_t bin = 0; bin < bins; ++bin) if (open[bin]) ++partial_open;
        while (partial_open > 2) {
            std::size_t weakest = bins;
            for (std::size_t bin = 0; bin < bins; ++bin) if (open[bin] && (weakest == bins || loads[bin] < loads[weakest] || (loads[bin] == loads[weakest] && bin > weakest))) weakest = bin;
            open[weakest] = false; --partial_open;
        }
    }
    const auto bytes = 8 * (n + 1);
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, static_cast<std::int64_t>(bins));
    for (std::size_t item = 0; item < n; ++item) put_i64(output, item + 1, assignments[item]);
    return static_cast<std::int64_t>(bytes);
}
