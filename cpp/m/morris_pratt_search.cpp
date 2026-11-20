#include <cstddef>
#include <cstdint>

extern "C" std::int64_t morris_pratt_search(const std::int64_t* input,
                                               std::size_t length) noexcept {
    constexpr std::size_t max_text = 4096, max_pattern = 128, max_input = 4227;
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_text) ||
        m64 < 1 || m64 > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    if (length != 2 + n + m) return -1;
    const auto pattern_start = 2 + n;
    for (std::size_t q = 0; q < n + m; ++q)
        if (input[2 + q] < 0 || input[2 + q] > 3) return -1;

    std::int64_t mp_next[max_pattern + 1]{};
    mp_next[0] = -1;
    for (std::size_t index = 0; index < m; ++index) {
        auto border = mp_next[index];
        while (border >= 0 && input[pattern_start + index] != input[pattern_start + static_cast<std::size_t>(border)])
            border = mp_next[static_cast<std::size_t>(border)];
        mp_next[index + 1] = border + 1;
    }

    std::int64_t matched = 0, count = 0, offset_sum = 0, offset_xor = 0;
    for (std::size_t text_index = 0; text_index < n; ++text_index) {
        while (matched >= 0 && input[pattern_start + static_cast<std::size_t>(matched)] != input[2 + text_index])
            matched = mp_next[static_cast<std::size_t>(matched)];
        ++matched;
        if (static_cast<std::size_t>(matched) == m) {
            const auto start = static_cast<std::int64_t>(text_index + 1) - matched;
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            matched = mp_next[m];
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
