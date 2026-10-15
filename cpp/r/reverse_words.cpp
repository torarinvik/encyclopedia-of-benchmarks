#include <cstddef>
#include <cstdint>

extern "C" std::int64_t reverse_words(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 256 || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (output == nullptr || capacity < n + 1) return -2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto b = input[i + 1];
        if (!(b == 32 || (b >= 33 && b <= 126))) return -1;
        if (b == 32 && (i == 0 || i + 1 == n || input[i] == 32)) return -1;
    }
    std::size_t written = 0, end = n;
    while (end > 0) {
        std::size_t start = end;
        while (start > 0 && input[start] != 32) --start;
        const std::size_t word_start = start;
        for (std::size_t i = word_start; i < end; ++i) output[written++] = static_cast<std::uint8_t>(input[i + 1]);
        if (word_start == 0) break;
        output[written++] = 32;
        end = start - 1;
    }
    output[written] = 0;
    return static_cast<std::int64_t>(written);
}
