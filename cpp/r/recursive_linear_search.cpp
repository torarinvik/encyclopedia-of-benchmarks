#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_N = 64;
int search_recursive(const std::int32_t *items, int left, int right, std::int32_t target) noexcept {
    if (left > right) return -1;
    if (items[left] == target) return left;
    if (items[right] == target) return right;
    return search_recursive(items, left + 1, right - 1, target);
} }

extern "C" std::int64_t recursive_linear_search(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > MAX_N + 2) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(MAX_N) || length != static_cast<std::size_t>(input[0]) + 2) return -1;
    if (input[1] < INT32_MIN || input[1] > INT32_MAX) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::int32_t items[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
        items[i] = static_cast<std::int32_t>(input[i + 2]);
        for (std::size_t j = 0; j < i; ++j) if (items[j] == items[i]) return -1;
    }
    return search_recursive(items, 0, static_cast<int>(n) - 1, static_cast<std::int32_t>(input[1]));
}
