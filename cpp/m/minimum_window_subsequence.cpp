#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_window_subsequence(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 258) return -1;
    if (input[0] < 0 || input[0] > 128) return -1;
    const std::size_t search_length = static_cast<std::size_t>(input[0]);
    const std::size_t pattern_length_index = search_length + 1;
    if (length <= pattern_length_index) return -1;
    const std::int64_t pattern_length_value = input[pattern_length_index];
    if (pattern_length_value < 1 || pattern_length_value > 128) return -1;
    const std::size_t pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (length != search_length + pattern_length + 2) return -1;
    for (std::size_t i = 0; i < search_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    for (std::size_t j = 0; j < pattern_length; ++j)
        if (input[search_length + 2 + j] < 0 || input[search_length + 2 + j] > 127) return -1;

    std::int8_t latest_start[128];
    for (std::size_t j = 0; j < pattern_length; ++j) latest_start[j] = -1;
    std::int64_t best_start = -1;
    std::size_t best_length = search_length + 1;
    for (std::size_t end = 0; end < search_length; ++end) {
        const std::int64_t byte = input[end + 1];
        for (std::size_t j = pattern_length; j > 0; --j) {
            const std::size_t pattern_index = j - 1;
            if (byte != input[search_length + 2 + pattern_index]) continue;
            const int candidate = pattern_index == 0 ? static_cast<int>(end)
                                                       : static_cast<int>(latest_start[pattern_index - 1]);
            if (candidate >= 0 && candidate > latest_start[pattern_index])
                latest_start[pattern_index] = static_cast<std::int8_t>(candidate);
        }
        if (byte == input[search_length + 2 + pattern_length - 1] && latest_start[pattern_length - 1] >= 0) {
            const int start = latest_start[pattern_length - 1];
            const std::size_t window_length = end - static_cast<std::size_t>(start) + 1;
            if (window_length < best_length ||
                (window_length == best_length && (best_start < 0 || start < best_start))) {
                best_start = start;
                best_length = window_length;
            }
        }
    }
    if (best_start < 0) return 0;
    if (best_length > capacity || output == nullptr) return -2;
    for (std::size_t i = 0; i < best_length; ++i)
        output[i] = static_cast<std::uint8_t>(input[static_cast<std::size_t>(best_start) + 1 + i]);
    return static_cast<std::int64_t>(best_length);
}
