#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t backward_oracle_match(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 63) return -2;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    for (std::size_t i = 2; i < length; ++i) if (values[i] < 97 || values[i] > 122) return -2;
    if (m == 0) return 0;
    if (m > n) return -1;
    std::array<std::array<int, 26>, 64> next;
    std::array<int, 64> suffix;
    for (auto& row : next) row.fill(-1);
    suffix.fill(-1);
    for (std::size_t i = 0; i < m; ++i) {
        const auto letter = static_cast<std::size_t>(values[2 + n + m - 1 - i] - 97);
        next[i][letter] = static_cast<int>(i + 1);
        int k = suffix[i];
        while (k >= 0 && next[k][letter] < 0) {
            next[k][letter] = static_cast<int>(i + 1);
            k = suffix[k];
        }
        suffix[i + 1] = k < 0 ? 0 : next[k][letter];
    }
    std::size_t start = 0;
    while (start <= n - m) {
        int state = 0;
        auto remaining = m, shift = m;
        while (remaining > 0) {
            --remaining;
            state = next[state][static_cast<std::size_t>(values[2 + start + remaining] - 97)];
            if (state < 0) { shift = remaining + 1; break; }
            if (remaining == 0) return static_cast<std::int64_t>(start);
        }
        start += shift;
    }
    return -1;
}
