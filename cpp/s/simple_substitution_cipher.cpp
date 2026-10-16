#include <cstddef>
#include <cstdint>

extern "C" std::int64_t simple_substitution_cipher(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 28 || length > 284) return -1;
    const auto mode = input[0], n64 = input[27];
    if ((mode != 0 && mode != 1) || n64 < 0 || n64 > 256 || length != 28 + static_cast<std::size_t>(n64)) return -1;
    bool seen[26]{};
    for (std::size_t i = 0; i < 26; ++i) {
        const auto value = input[1 + i];
        if (value < 'A' || value > 'Z' || seen[value - 'A']) return -1;
        seen[value - 'A'] = true;
    }
    const auto n = static_cast<std::size_t>(n64);
    for (std::size_t i = 0; i < n; ++i) if (input[28 + i] < 0 || input[28 + i] > 127) return -1;
    if (output == nullptr || output_capacity < n) return -2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto ch = input[28 + i];
        const bool lower = ch >= 'a' && ch <= 'z', upper = ch >= 'A' && ch <= 'Z';
        if (!lower && !upper) { output[i] = static_cast<std::uint8_t>(ch); continue; }
        const auto index = static_cast<int>(ch - (lower ? 'a' : 'A'));
        int mapped = index;
        if (mode == 0) mapped = static_cast<int>(input[1 + index] - 'A');
        else { mapped = 0; while (mapped < 26 && input[1 + mapped] != 'A' + index) ++mapped; }
        output[i] = static_cast<std::uint8_t>((lower ? 'a' : 'A') + mapped);
    }
    return static_cast<std::int64_t>(n);
}
