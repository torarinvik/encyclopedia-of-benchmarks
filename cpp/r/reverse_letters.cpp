#include <cstddef>
#include <cstdint>

extern "C" std::int64_t reverse_letters(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value == 32) {
            if (i == 0 || i + 1 == n || input[i] == 32) return -1;
        } else if (value < 33 || value > 126) return -1;
    }
    if (output == nullptr || capacity < n + 1) return -2;
    std::size_t start = 0;
    while (start < n) {
        std::size_t end = start;
        while (end < n && input[end + 1] != 32) ++end;
        for (std::size_t i = 0; i < end - start + 1; ++i) output[start + i] = static_cast<std::uint8_t>(input[end - i]);
        if (end < n) output[end] = 32;
        start = end + 1;
    }
    output[n] = 0;
    return static_cast<std::int64_t>(n);
}
