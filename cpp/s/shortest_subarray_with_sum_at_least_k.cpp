#include <cstddef>
#include <cstdint>

extern "C" std::int64_t shortest_subarray_with_sum_at_least_k(
    const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 259) return -1;
    const std::int64_t target = packed[0];
    const std::int64_t count = packed[1];
    if (target < -4096 || target > 4096 || count < 0 || count > 256
        || length != static_cast<std::size_t>(count) + 2) return -1;

    std::int64_t prefix[257]{};
    for (std::int64_t index = 0; index < count; ++index) {
        const std::int64_t value = packed[index + 2];
        if (value < -1000 || value > 1000) return -1;
        prefix[index + 1] = prefix[index] + value;
    }

    std::size_t deque[257]{};
    std::size_t head = 0, tail = 0;
    std::int64_t best = count + 1;
    for (std::size_t right = 0; right <= static_cast<std::size_t>(count); ++right) {
        while (head < tail && prefix[right] - prefix[deque[head]] >= target) {
            const auto width = static_cast<std::int64_t>(right - deque[head]);
            if (width < best) best = width;
            ++head;
        }
        while (head < tail && prefix[right] <= prefix[deque[tail - 1]]) --tail;
        deque[tail++] = right;
    }
    return best <= count ? best : 0;
}

