/* Largest rectangle area in a bounded histogram. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -9'223'372'036'854'775'807LL - 1; }

extern "C" std::int64_t largest_rectangle_histogram(const std::int64_t *heights,
                                                       std::size_t length) noexcept
{
    if (length == 0) return 0;
    if (heights == nullptr || length > 64) return invalid_result;
    for (std::size_t index = 0; index < length; ++index) {
        if (heights[index] < 0 || heights[index] > 1'000'000) return invalid_result;
    }

    std::size_t stack[64];
    std::size_t top = 0;
    std::int64_t best = 0;
    for (std::size_t index = 0; index < length; ++index) {
        while (top > 0 && heights[stack[top - 1]] > heights[index]) {
            const std::size_t bar = stack[--top];
            const std::size_t left = top == 0 ? 0 : stack[top - 1] + 1;
            const std::int64_t area = heights[bar] * static_cast<std::int64_t>(index - left);
            best = best > area ? best : area;
        }
        stack[top++] = index;
    }
    while (top > 0) {
        const std::size_t bar = stack[--top];
        const std::size_t left = top == 0 ? 0 : stack[top - 1] + 1;
        const std::int64_t area = heights[bar] * static_cast<std::int64_t>(length - left);
        best = best > area ? best : area;
    }
    return best;
}
