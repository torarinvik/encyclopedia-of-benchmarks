#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_size_subarray_sum(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2) return -1;
    const auto target = packed[0];
    const auto count = packed[1];
    if (target < 1 || target > 1000000 || count < 0 || count > 256
        || length != static_cast<std::size_t>(count) + 2) return -1;
    for (std::int64_t index = 0; index < count; ++index) {
        if (packed[index + 2] < 1 || packed[index + 2] > 1000000) return -1;
    }
    std::int64_t left = 0, sum = 0, best = count + 1;
    for (std::int64_t right = 0; right < count; ++right) {
        sum += packed[right + 2];
        while (sum >= target) {
            const auto width = right - left + 1;
            if (width < best) best = width;
            sum -= packed[left + 2];
            ++left;
        }
    }
    return best <= count ? best : 0;
}
