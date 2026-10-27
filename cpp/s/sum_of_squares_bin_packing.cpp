#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t sum_of_squares_bin_packing(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 66) return -1;
    const auto capacity0 = input[0], n0 = input[1];
    if (capacity0 < 1 || capacity0 > 64 || n0 < 0 || n0 > 64 || length != 2 + static_cast<std::size_t>(n0)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 2] < 1 || input[i + 2] > capacity0) return -1;
    std::int64_t histogram[65] = {}, loads[64] = {}, assignments[64] = {};
    std::size_t bins = 0;
    std::int64_t score = 0;
    for (std::size_t item = 0; item < n; ++item) {
        const auto size = input[item + 2];
        std::size_t selected = bins;
        auto best_score = std::numeric_limits<std::int64_t>::max();
        for (std::size_t bin = 0; bin < bins; ++bin) {
            const auto from = loads[bin], to = from + size;
            if (to > capacity0) continue;
            auto candidate = score;
            if (from < capacity0) candidate += (histogram[from] - 1) * (histogram[from] - 1) - histogram[from] * histogram[from];
            if (to < capacity0) candidate += (histogram[to] + 1) * (histogram[to] + 1) - histogram[to] * histogram[to];
            if (candidate < best_score) { best_score = candidate; selected = bin; }
        }
        auto new_score = score;
        if (size < capacity0) new_score += (histogram[size] + 1) * (histogram[size] + 1) - histogram[size] * histogram[size];
        if (new_score < best_score) { best_score = new_score; selected = bins; }
        if (selected == bins) {
            loads[bins] = size; assignments[item] = static_cast<std::int64_t>(bins);
            if (size < capacity0) ++histogram[size];
            ++bins;
        } else {
            const auto from = loads[selected], to = from + size;
            if (from < capacity0) --histogram[from];
            if (to < capacity0) ++histogram[to];
            loads[selected] = to; assignments[item] = static_cast<std::int64_t>(selected);
        }
        score = best_score;
    }
    const auto bytes = 8 * (n + 1);
    if (output == nullptr || output_capacity < bytes) return -2;
    put_i64(output, 0, static_cast<std::int64_t>(bins));
    for (std::size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignments[i]);
    return static_cast<std::int64_t>(bytes);
}
