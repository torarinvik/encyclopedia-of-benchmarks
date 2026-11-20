#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 256;
constexpr std::size_t max_pattern = 16;
constexpr std::size_t alphabet = 16;
constexpr std::size_t max_input = 274;
}

extern "C" std::int64_t zhu_takaoka_search(const std::int64_t* values,
                                              std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_input) return -2;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_text) ||
        values[1] < 2 || values[1] > static_cast<std::int64_t>(max_pattern)) return -2;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    for (std::size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= static_cast<std::int64_t>(alphabet)) return -2;
    if (m > n) return -1;

    const std::size_t p = 2 + n;
    std::array<std::array<std::size_t, alphabet>, alphabet> pair_shift{};
    for (auto& row : pair_shift) row.fill(m);
    for (std::size_t a = 0; a < alphabet; ++a)
        pair_shift[a][static_cast<std::size_t>(values[p])] = m - 1;
    for (std::size_t i = 1; i + 1 < m; ++i)
        pair_shift[static_cast<std::size_t>(values[p + i - 1])]
                  [static_cast<std::size_t>(values[p + i])] = m - 1 - i;

    std::array<std::size_t, max_pattern> good_suffix{};
    for (std::size_t mismatch = 0; mismatch < m; ++mismatch) {
        good_suffix[mismatch] = m;
        for (std::size_t shift = 1; shift <= m; ++shift) {
            const std::size_t first_known = mismatch + 1 > shift ? mismatch + 1 : shift;
            std::size_t position = first_known;
            while (position < m && values[p + position] == values[p + position - shift])
                ++position;
            if (position < m) continue;
            if (mismatch + 1 < m && shift <= mismatch &&
                values[p + mismatch - shift] == values[p + mismatch])
                continue;
            good_suffix[mismatch] = shift;
            break;
        }
    }

    std::size_t start = 0;
    while (start <= n - m) {
        std::size_t mismatch = m;
        while (mismatch > 0 && values[p + mismatch - 1] == values[2 + start + mismatch - 1])
            --mismatch;
        if (mismatch == 0) return static_cast<std::int64_t>(start);
        --mismatch;
        const auto first = static_cast<std::size_t>(values[2 + start + m - 2]);
        const auto second = static_cast<std::size_t>(values[2 + start + m - 1]);
        start += std::max(good_suffix[mismatch], pair_shift[first][second]);
    }
    return -1;
}
