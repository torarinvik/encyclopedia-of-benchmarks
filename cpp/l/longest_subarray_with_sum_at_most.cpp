#include <cstddef>
#include <cstdint>
namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::size_t max_input_length = 259;
constexpr std::int64_t max_domain_value = 2147483647;
}
extern "C" std::int64_t longest_subarray_with_sum_at_most(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return invalid_result;
    const auto target = input[0], raw_count = input[1];
    if (target < 0 || target > max_domain_value || raw_count < 0 || raw_count > 256) return invalid_result;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != count + 2) return invalid_result;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 2];
        if (value < 0 || value > max_domain_value) return invalid_result;
    }
    std::size_t left = 0, best_length = 0;
    std::int64_t window_sum = 0;
    for (std::size_t right = 0; right < count; ++right) {
        window_sum += input[right + 2];
        while (window_sum > target && left <= right) {
            window_sum -= input[left + 2];
            ++left;
        }
        const auto current_length = left <= right ? right - left + 1 : 0;
        if (current_length > best_length) best_length = current_length;
    }
    return static_cast<std::int64_t>(best_length);
}
