#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSamples = 8;
constexpr std::size_t MaxCellVertices = 8;

void store_i64_le(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
bool same_point(const std::array<std::int64_t, 3>& a, const std::array<std::int64_t, 3>& b) {
    return a == b;
}
}

extern "C" std::int64_t crust_opposite_pole_selection(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 226) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > 8) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    std::array<std::array<std::int64_t, 3>, MaxSamples> samples{};
    std::array<std::array<std::int64_t, 2>, MaxSamples> answer{};
    std::size_t offset = 1;
    for (std::size_t row = 0; row < n; ++row) {
        if (offset + 4 > length) return -1;
        const std::array<std::int64_t, 3> sample{input[offset], input[offset + 1], input[offset + 2]};
        const auto count_raw = input[offset + 3];
        offset += 4;
        if (count_raw < 1 || count_raw > 8) return -1;
        const auto count = static_cast<std::size_t>(count_raw);
        for (const auto coordinate : sample) if (coordinate < -16 || coordinate > 16) return -1;
        for (std::size_t prev = 0; prev < row; ++prev) if (same_point(sample, samples[prev])) return -1;
        samples[row] = sample;
        if (offset + 3 * count > length) return -1;
        std::array<std::array<std::int64_t, 3>, MaxCellVertices> cell{};
        for (std::size_t v = 0; v < count; ++v) {
            for (std::size_t axis = 0; axis < 3; ++axis) {
                cell[v][axis] = input[offset++];
                if (cell[v][axis] < -16 || cell[v][axis] > 16) return -1;
            }
            if (same_point(sample, cell[v])) return -1;
            for (std::size_t prev = 0; prev < v; ++prev) if (same_point(cell[v], cell[prev])) return -1;
        }
        std::size_t positive = 0;
        std::int64_t positive_distance = -1;
        for (std::size_t v = 0; v < count; ++v) {
            std::int64_t distance = 0;
            for (std::size_t axis = 0; axis < 3; ++axis) {
                const auto delta = cell[v][axis] - sample[axis]; distance += delta * delta;
            }
            if (distance > positive_distance) { positive_distance = distance; positive = v; }
        }
        std::array<std::int64_t, 3> forward{};
        for (std::size_t axis = 0; axis < 3; ++axis) forward[axis] = cell[positive][axis] - sample[axis];
        std::int64_t negative = -1, negative_distance = -1;
        for (std::size_t v = 0; v < count; ++v) {
            std::int64_t distance = 0, projection = 0;
            for (std::size_t axis = 0; axis < 3; ++axis) {
                const auto delta = cell[v][axis] - sample[axis]; distance += delta * delta; projection += delta * forward[axis];
            }
            if (projection < 0 && distance > negative_distance) { negative_distance = distance; negative = static_cast<std::int64_t>(v); }
        }
        answer[row] = {static_cast<std::int64_t>(positive), negative};
    }
    if (offset != length) return -1;
    const std::size_t bytes = 8 * (1 + 2 * n);
    if (output == nullptr || capacity < bytes) return -2;
    store_i64_le(output, 0, n_raw);
    std::size_t word = 1;
    for (std::size_t row = 0; row < n; ++row) { store_i64_le(output, word++, answer[row][0]); store_i64_le(output, word++, answer[row][1]); }
    return static_cast<std::int64_t>(bytes);
}
