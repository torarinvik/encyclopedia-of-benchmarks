#include <cstddef>
#include <cstdint>

namespace {
constexpr int ROWS = 8, COLS = 8, INPUT = 66, OUTPUT = 24;
int interval_cost(const std::int64_t *table, int rows, int cols, int begin, int end) {
    int runs = 0;
    bool have_previous = false;
    std::int64_t previous = 0;
    for (int row = 0; row < rows; ++row) {
        for (int col = begin; col < end; ++col) {
            const auto value = table[row * cols + col];
            if (!have_previous || value != previous) ++runs;
            previous = value;
            have_previous = true;
        }
    }
    return 2 * runs;
}
void put(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[offset + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t table_compression_optimal_contiguous_partition(
    const std::int64_t *values, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!values || length < 3 || length > INPUT || values[0] < 1 || values[0] > ROWS ||
        values[1] < 1 || values[1] > COLS) return -1;
    const int rows = static_cast<int>(values[0]), cols = static_cast<int>(values[1]);
    if (length != static_cast<std::size_t>(2 + rows * cols)) return -1;
    for (int i = 0; i < rows * cols; ++i) if (values[2 + i] < 0 || values[2 + i] > 15) return -1;

    int cost[COLS + 1]{}, previous[COLS + 1]{};
    for (int end = 1; end <= cols; ++end) {
        cost[end] = 0x3fffffff;
        for (int start = 0; start < end; ++start) {
            const int candidate = cost[start] + interval_cost(values + 2, rows, cols, start, end);
            if (candidate < cost[end]) { cost[end] = candidate; previous[end] = start; }
        }
    }
    int groups = 0;
    std::uint64_t cuts = 0;
    for (int end = cols; end > 0; end = previous[end]) {
        const int start = previous[end];
        if (start > 0) cuts |= std::uint64_t(1) << (start - 1);
        ++groups;
    }
    std::uint8_t staged[OUTPUT]{};
    put(staged, 0, cost[cols]); put(staged, 8, groups); put(staged, 16, static_cast<std::int64_t>(cuts));
    if (!output || capacity < OUTPUT) return -2;
    for (int i = 0; i < OUTPUT; ++i) output[i] = staged[i];
    return OUTPUT;
}
