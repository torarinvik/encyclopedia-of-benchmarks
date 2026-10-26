#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxSymbols = 20, kMaxClen = 32;
}

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
extern "C" std::int64_t mediabench_jpeg_optimal_huffman_table(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 3 || length > 41 || input[0] < 1 || input[0] > kMaxSymbols) return -1;
    const int count = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(1 + 2 * count)) return -1;
    for (int i = 0; i < count; ++i) {
        const auto symbol = input[1 + 2 * i], frequency = input[2 + 2 * i];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > 1000000) return -1;
        for (int j = 0; j < i; ++j) if (input[1 + 2 * j] == symbol) return -1;
    }
    const std::size_t out_size = static_cast<std::size_t>(17 + count);
    if (!output || capacity < out_size) return -2;
    std::array<std::int64_t, 257> freq{};
    std::array<int, 257> code_size{};
    std::array<int, 257> others{};
    std::array<int, kMaxClen + 1> bits{};
    others.fill(-1);
    for (int i = 0; i < count; ++i) freq[static_cast<std::size_t>(input[1 + 2 * i])] = input[2 + 2 * i];
    freq[256] = 1;
    for (;;) {
        int c1 = -1, c2 = -1;
        std::int64_t value = 1000000000;
        for (int i = 0; i <= 256; ++i) if (freq[i] != 0 && freq[i] <= value) { value = freq[i]; c1 = i; }
        value = 1000000000;
        for (int i = 0; i <= 256; ++i) if (freq[i] != 0 && freq[i] <= value && i != c1) { value = freq[i]; c2 = i; }
        if (c2 < 0) break;
        freq[c1] += freq[c2]; freq[c2] = 0;
        ++code_size[c1]; while (others[c1] >= 0) { c1 = others[c1]; ++code_size[c1]; }
        others[c1] = c2;
        ++code_size[c2]; while (others[c2] >= 0) { c2 = others[c2]; ++code_size[c2]; }
    }
    for (int i = 0; i <= 256; ++i) if (code_size[i] != 0) {
        if (code_size[i] > kMaxClen) return -1;
        ++bits[code_size[i]];
    }
    for (int i = kMaxClen; i > 16; --i) while (bits[i] > 0) {
        int j = i - 2; while (j >= 0 && bits[j] == 0) --j;
        if (j < 0 || bits[i] < 2) return -1;
        bits[i] -= 2; ++bits[i - 1]; bits[j + 1] += 2; --bits[j];
    }
    int longest = 16; while (longest > 0 && bits[longest] == 0) --longest;
    if (longest == 0) return -1;
    --bits[longest];
    int symbol_count = 0;
    for (int size = 1; size <= kMaxClen; ++size)
        for (int symbol = 0; symbol <= 255; ++symbol) if (code_size[symbol] == size) ++symbol_count;
    if (symbol_count != count) return -1;
    output[0] = static_cast<std::uint8_t>(count);
    for (int i = 1; i <= 16; ++i) output[i] = static_cast<std::uint8_t>(bits[i]);
    int out = 17;
    for (int size = 1; size <= kMaxClen; ++size)
        for (int symbol = 0; symbol <= 255; ++symbol)
            if (code_size[symbol] == size) output[out++] = static_cast<std::uint8_t>(symbol);
    return static_cast<std::int64_t>(out_size);
}
