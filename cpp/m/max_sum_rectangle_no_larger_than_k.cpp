#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxRows = 8;
constexpr std::size_t kMaxColumns = 8;
constexpr std::int64_t kNoFeasible = -1025;
constexpr std::int64_t kInvalidInput = -1026;

std::int64_t best_subarray_at_most(const std::array<std::int64_t, kMaxColumns>& values,
                                   std::size_t count, std::int64_t limit) noexcept {
    std::array<std::int64_t, kMaxColumns + 1> prefixes{};
    std::size_t prefix_count = 1;
    std::int64_t running = 0;
    std::int64_t best = kNoFeasible;
    for (std::size_t i = 0; i < count; ++i) {
        running += values[i];
        const std::int64_t threshold = running - limit;
        std::size_t low = 0, high = prefix_count;
        while (low < high) {
            const std::size_t middle = low + (high - low) / 2;
            if (prefixes[middle] < threshold) low = middle + 1;
            else high = middle;
        }
        if (low < prefix_count) {
            const std::int64_t candidate = running - prefixes[low];
            if (best == kNoFeasible || candidate > best) best = candidate;
        }
        std::size_t insert = prefix_count;
        while (insert > 0 && prefixes[insert - 1] > running) {
            prefixes[insert] = prefixes[insert - 1];
            --insert;
        }
        prefixes[insert] = running;
        ++prefix_count;
    }
    return best;
}
}

extern "C" std::int64_t max_sum_rectangle_no_larger_than_k(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 68) return kInvalidInput;
    const std::int64_t rows_value = input[0], columns_value = input[1], limit = input[2];
    if (rows_value < 1 || rows_value > static_cast<std::int64_t>(kMaxRows)
        || columns_value < 1 || columns_value > static_cast<std::int64_t>(kMaxColumns)
        || limit < -1024 || limit > 1024) return kInvalidInput;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    if (length != 3 + rows * columns) return kInvalidInput;

    std::array<std::array<std::int64_t, kMaxColumns>, kMaxRows> matrix{};
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            const std::int64_t value = input[3 + row * columns + column];
            if (value < -16 || value > 16) return kInvalidInput;
            matrix[row][column] = value;
        }
    }
    const std::size_t short_dimension = rows < columns ? rows : columns;
    const std::size_t long_dimension = rows < columns ? columns : rows;
    std::int64_t best = kNoFeasible;
    for (std::size_t first = 0; first < short_dimension; ++first) {
        std::array<std::int64_t, kMaxColumns> compressed{};
        for (std::size_t last = first; last < short_dimension; ++last) {
            for (std::size_t offset = 0; offset < long_dimension; ++offset) {
                compressed[offset] += rows <= columns
                    ? matrix[last][offset] : matrix[offset][last];
            }
            const std::int64_t candidate = best_subarray_at_most(compressed, long_dimension, limit);
            if (candidate != kNoFeasible && (best == kNoFeasible || candidate > best)) {
                best = candidate;
                if (best == limit) return best;
            }
        }
    }
    return best;
}
