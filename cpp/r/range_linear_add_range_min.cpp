#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 64;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input = 387;
constexpr std::size_t block_width = 8;
constexpr std::size_t max_blocks = 8;
constexpr std::int64_t checksum_offset = 8000000;

using Values = std::array<std::int64_t, max_length>;
using Hull = std::array<std::int64_t, max_length>;
using Counts = std::array<std::size_t, max_blocks>;
using BlockValues = std::array<std::int64_t, max_blocks>;

std::size_t end_of_block(std::size_t block, std::size_t n) {
    return std::min((block + 1) * block_width, n);
}

void rebuild(const Values& data, Hull& hx, Hull& hy, Counts& count,
             std::size_t block, std::size_t n) {
    const auto base = block * block_width;
    std::size_t size = 0;
    for (std::size_t x = base; x < end_of_block(block, n); ++x) {
        while (size >= 2) {
            const auto p = base + size - 2;
            const auto q = base + size - 1;
            const auto cross = (hx[q] - hx[p]) * (data[x] - hy[p])
                - (hy[q] - hy[p]) * (static_cast<std::int64_t>(x) - hx[p]);
            if (cross > 0) break;
            --size;
        }
        hx[base + size] = static_cast<std::int64_t>(x);
        hy[base + size] = data[x];
        ++size;
    }
    count[block] = size;
}

void push(Values& data, BlockValues& slope, BlockValues& intercept,
          std::size_t block, std::size_t n) {
    const auto start = block * block_width;
    for (auto i = start; i < end_of_block(block, n); ++i)
        data[i] += slope[block] * static_cast<std::int64_t>(i) + intercept[block];
    slope[block] = 0;
    intercept[block] = 0;
}

std::int64_t block_min(const Hull& hx, const Hull& hy, const Counts& count,
                       const BlockValues& slope, const BlockValues& intercept,
                       std::size_t block) {
    const auto base = block * block_width;
    std::size_t lo = 0, hi = count[block] - 1;
    while (lo < hi) {
        const auto mid = lo + (hi - lo) / 2;
        const auto left = hy[base + mid] + slope[block] * hx[base + mid];
        const auto right = hy[base + mid + 1] + slope[block] * hx[base + mid + 1];
        if (left <= right) hi = mid;
        else lo = mid + 1;
    }
    return hy[base + lo] + slope[block] * hx[base + lo] + intercept[block];
}
} // namespace

extern "C" std::int64_t range_linear_add_range_min_benchmark(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input || input[0] < 1 ||
        input[0] > static_cast<std::int64_t>(max_length) || input[1] < 1 ||
        input[1] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length < n + 2) return -1;
    Values data{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 2] < -1000000 || input[i + 2] > 1000000) return -1;
        data[i] = input[i + 2];
    }
    Hull hx{}, hy{};
    Counts count{};
    BlockValues lazy_slope{}, lazy_intercept{};
    const auto blocks = (n + block_width - 1) / block_width;
    for (std::size_t block = 0; block < blocks; ++block)
        rebuild(data, hx, hy, count, block, n);

    std::size_t cursor = n + 2;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            const auto left_value = input[cursor++], right_value = input[cursor++];
            const auto slope = input[cursor++], intercept = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > static_cast<std::int64_t>(n) ||
                slope < -99 || slope > 99 || intercept < -100000 || intercept > 100000) return -1;
            auto position = static_cast<std::size_t>(left_value);
            const auto right = static_cast<std::size_t>(right_value);
            while (position < right) {
                const auto block = position / block_width;
                const auto start = block * block_width;
                const auto end = end_of_block(block, n);
                if (position == start && end <= right) {
                    lazy_slope[block] += slope;
                    lazy_intercept[block] += intercept;
                    position = end;
                } else {
                    push(data, lazy_slope, lazy_intercept, block, n);
                    const auto stop = std::min(end, right);
                    for (auto i = position; i < stop; ++i)
                        data[i] += slope * static_cast<std::int64_t>(i) + intercept;
                    rebuild(data, hx, hy, count, block, n);
                    position = stop;
                }
            }
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            const auto left_value = input[cursor++], right_value = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > static_cast<std::int64_t>(n)) return -1;
            auto position = static_cast<std::size_t>(left_value);
            const auto right = static_cast<std::size_t>(right_value);
            auto minimum = std::numeric_limits<std::int64_t>::max();
            while (position < right) {
                const auto block = position / block_width;
                const auto start = block * block_width;
                const auto end = end_of_block(block, n);
                if (position == start && end <= right) {
                    minimum = std::min(minimum, block_min(hx, hy, count, lazy_slope,
                                                          lazy_intercept, block));
                    position = end;
                } else {
                    const auto stop = std::min(end, right);
                    for (auto i = position; i < stop; ++i)
                        minimum = std::min(minimum, data[i] + lazy_slope[block] * static_cast<std::int64_t>(i)
                                                   + lazy_intercept[block]);
                    position = stop;
                }
            }
            checksum += static_cast<std::int64_t>(operation + 1) * (minimum + checksum_offset);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
