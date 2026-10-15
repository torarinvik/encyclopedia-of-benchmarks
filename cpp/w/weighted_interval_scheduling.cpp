#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INTERVALS = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 1 + 3 * MAX_INTERVALS;

std::int64_t start_at(const std::int64_t *input, std::size_t index) { return input[1 + index * 3]; }
std::int64_t end_at(const std::int64_t *input, std::size_t index) { return input[2 + index * 3]; }
std::int64_t weight_at(const std::int64_t *input, std::size_t index) { return input[3 + index * 3]; }

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void put_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t weighted_interval_scheduling(const std::int64_t *input, std::size_t length,
                                                       std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_INTERVALS)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * n) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto start = start_at(input, i), end = end_at(input, i), weight = weight_at(input, i);
        if (start < -100000 || start > 100000 || end < -100000 || end > 100000 || start >= end
            || weight < 0 || weight > 1000000) return -1;
    }
    std::size_t order[MAX_INTERVALS], predecessors[MAX_INTERVALS], selected[MAX_INTERVALS];
    std::int64_t dp[MAX_INTERVALS + 1] = {};
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0 && end_at(input, order[j - 1]) > end_at(input, key)) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    for (std::size_t j = 0; j < n; ++j) {
        std::size_t low = 0, high = n;
        while (low < high) {
            const auto mid = low + (high - low) / 2;
            if (end_at(input, order[mid]) <= start_at(input, order[j])) low = mid + 1;
            else high = mid;
        }
        predecessors[j] = low;
        const auto include = weight_at(input, order[j]) + dp[low];
        dp[j + 1] = include > dp[j] ? include : dp[j];
    }
    std::size_t selected_count = 0, current = n;
    while (current > 0) {
        const auto j = current - 1;
        const auto include = weight_at(input, order[j]) + dp[predecessors[j]];
        if (include > dp[current - 1]) { selected[selected_count++] = order[j]; current = predecessors[j]; }
        else --current;
    }
    for (std::size_t i = 0; i < selected_count / 2; ++i) {
        const auto temp = selected[i]; selected[i] = selected[selected_count - 1 - i]; selected[selected_count - 1 - i] = temp;
    }
    const auto needed = 16 + 4 * selected_count;
    if (output == nullptr || capacity < needed) return -2;
    put_i64_le(output, 0, dp[n]);
    put_i64_le(output, 8, static_cast<std::int64_t>(selected_count));
    for (std::size_t i = 0; i < selected_count; ++i) put_i32_le(output, 16 + 4 * i, static_cast<std::int32_t>(selected[i]));
    return static_cast<std::int64_t>(needed);
}
