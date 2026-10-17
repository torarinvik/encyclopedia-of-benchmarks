#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;
constexpr std::size_t max_input_length = max_length + 1;

char* miroir(char* s) noexcept {
    std::size_t n = 0;
    while (s[n] != '\0') ++n;
    if (n == 0) return s;
    std::size_t i = 0, k = n - 1;
    while (i <= k) {
        const char aux = s[i];
        s[i] = s[k];
        s[k] = aux;
        ++i;
        if (k == 0) break;
        --k;
    }
    return s;
}
}

extern "C" std::int64_t mirror(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_length)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 127) return -1;
    if (output == nullptr || capacity < n + 1) return -2;
    char buffer[max_input_length]{};
    for (std::size_t i = 0; i < n; ++i) buffer[i] = static_cast<char>(input[i + 1]);
    buffer[n] = '\0';
    char* mirrored = miroir(buffer);
    for (std::size_t i = 0; i < n; ++i) output[i] = static_cast<std::uint8_t>(mirrored[i]);
    output[n] = 0;
    return static_cast<std::int64_t>(n);
}
