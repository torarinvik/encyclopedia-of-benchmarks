#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_list_length = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_list_length;
constexpr std::int64_t max_value = 2147483647;
}

extern "C" std::int64_t sublist_search(const std::int64_t* values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    const auto main_count_value = values[0];
    const auto pattern_count_value = values[1];
    if (main_count_value < 0 || main_count_value > static_cast<std::int64_t>(max_list_length) ||
        pattern_count_value < 0 || pattern_count_value > static_cast<std::int64_t>(max_list_length)) return -1;
    const auto main_count = static_cast<std::size_t>(main_count_value);
    const auto pattern_count = static_cast<std::size_t>(pattern_count_value);
    if (length != 2 + main_count + pattern_count) return -1;
    for (std::size_t i = 0; i < main_count + pattern_count; ++i)
        if (values[2 + i] < 0 || values[2 + i] > max_value) return -1;

    if (main_count == 0 || pattern_count == 0 || pattern_count > main_count) return 0;
    const auto pattern_offset = 2 + main_count;
    for (std::size_t start = 0; start + pattern_count <= main_count; ++start) {
        std::size_t matched = 0;
        while (matched < pattern_count &&
               values[2 + start + matched] == values[pattern_offset + matched]) ++matched;
        if (matched == pattern_count) return 1;
    }
    return 0;
}
