#include <cstddef>
#include <cstdint>

extern "C" std::int64_t reverse_string(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 33 || input[i + 1] > 126) return -1;
    }
    if (output == nullptr || capacity < n + 1) return -2;
    for (std::size_t i = 0; i < n; ++i) output[i] = static_cast<std::uint8_t>(input[n - i]);
    output[n] = 0;
    return static_cast<std::int64_t>(n);
}
