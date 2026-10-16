#include <cstddef>
#include <cstdint>
extern "C" int64_t reverse_array(const int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (length < 1 || length > 257 || input == nullptr) return -1;
    const int64_t count = input[0];
    if (count < 1 || count > 256 || length != static_cast<std::size_t>(count) + 1) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    if (capacity < static_cast<std::size_t>(count) || output == nullptr) return -2;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) output[i] = static_cast<std::uint8_t>(input[i + 1]);
    for (std::size_t left = 0, right = static_cast<std::size_t>(count) - 1; left < right; ++left, --right) { auto tmp = output[left]; output[left] = output[right]; output[right] = tmp; }
    return count;
}
