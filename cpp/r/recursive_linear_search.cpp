// Backward recursive linear search over a bounded integer array.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr std::size_t max_input_length = max_count + 3;

std::int64_t search_from_end(const std::int64_t *items, std::size_t count,
                             std::int64_t target) noexcept {
    if (count == 0) return -1;
    if (items[count - 1] == target) return static_cast<std::int64_t>(count - 1);
    return search_from_end(items, count - 1, target);
}
}

extern "C" std::int64_t recursive_linear_search(const std::int64_t *values,
                                                   std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    const auto count_value = values[0];
    const auto target = values[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_count)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;
    return search_from_end(values + 2, count, target);
}
