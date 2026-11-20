#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;

bool advance_sample(const std::array<std::uint8_t, max_text>& text, int n, int m,
                    const std::array<int, 4>& last, int& sample, int& position) {
    do {
        sample += m;
    } while (sample < n && last[text[static_cast<std::size_t>(sample)]] < 0);
    if (sample >= n) return false;
    position = last[text[static_cast<std::size_t>(sample)]];
    return true;
}
} // namespace

extern "C" std::int64_t kmp_skip_search(const std::int64_t* input,
                                         std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_text) ||
        m64 < 1 || m64 > static_cast<std::int64_t>(max_pattern)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    if (length != static_cast<std::size_t>(2 + n + m)) return -1;

    std::array<std::uint8_t, max_text> text{};
    std::array<std::uint8_t, max_pattern> pattern{};
    for (int q = 0; q < n; ++q) {
        const std::int64_t symbol = input[2 + q];
        if (symbol < 0 || symbol > 3) return -1;
        text[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(symbol);
    }
    for (int q = 0; q < m; ++q) {
        const std::int64_t symbol = input[2 + n + q];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(symbol);
    }
    if (n < m) return 0;

    std::array<int, max_pattern + 1> mp_next{};
    std::array<int, max_pattern + 1> kmp_next{};
    int q = 0, border = -1;
    mp_next[0] = -1;
    while (q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = mp_next[border];
        ++q;
        ++border;
        mp_next[q] = border;
    }
    q = 0;
    border = -1;
    kmp_next[0] = -1;
    while (q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = kmp_next[border];
        ++q;
        ++border;
        if (q < m && pattern[q] == pattern[border]) kmp_next[q] = kmp_next[border];
        else kmp_next[q] = border;
    }

    std::array<int, 4> last{-1, -1, -1, -1};
    std::array<int, max_pattern> previous{};
    for (int q = 0; q < m; ++q) {
        previous[static_cast<std::size_t>(q)] = last[pattern[static_cast<std::size_t>(q)]];
        last[pattern[static_cast<std::size_t>(q)]] = q;
    }

    int sample = -1, i = -1;
    if (!advance_sample(text, n, m, last, sample, i)) return 0;
    int start = sample - i;
    int wall = 0;
    const int period = m - kmp_next[static_cast<std::size_t>(m)];
    std::int64_t count = 0, offset_sum = 0, offset_xor = 0;
    while (start <= n - m) {
        if (start > wall) wall = start;
        int k = wall - start;
        while (k < m && pattern[static_cast<std::size_t>(k)] == text[static_cast<std::size_t>(start + k)]) ++k;
        wall = start + k;
        if (k == m) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            i -= period;
        } else {
            i = previous[static_cast<std::size_t>(i)];
        }
        if (i < 0 && !advance_sample(text, n, m, last, sample, i)) break;

        int kmp_start = start + k - kmp_next[static_cast<std::size_t>(k)];
        k = kmp_next[static_cast<std::size_t>(k)];
        start = sample - i;
        while (start < kmp_start || (kmp_start < start && start < wall)) {
            if (start < kmp_start) {
                i = previous[static_cast<std::size_t>(i)];
                if (i < 0 && !advance_sample(text, n, m, last, sample, i)) break;
                if (i < 0) break;
                start = sample - i;
            } else {
                kmp_start += k - mp_next[static_cast<std::size_t>(k)];
                k = mp_next[static_cast<std::size_t>(k)];
            }
        }
        if (i < 0) break;
    }
    const std::uint64_t packed = (static_cast<std::uint64_t>(count) << 36) |
                                 (static_cast<std::uint64_t>(offset_sum) << 12) |
                                 static_cast<std::uint64_t>(offset_xor);
    return static_cast<std::int64_t>(packed);
}
