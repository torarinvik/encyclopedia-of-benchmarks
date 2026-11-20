#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;
}

extern "C" std::int64_t reverse_colussi_search(const std::int64_t* input,
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
        const std::int64_t value = input[2 + q];
        if (value < 0 || value > 3) return -1;
        text[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(value);
    }
    for (int q = 0; q < m; ++q) {
        const std::int64_t value = input[2 + n + q];
        if (value < 0 || value > 3) return -1;
        pattern[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(value);
    }
    if (n < m) return 0;

    std::array<int, max_pattern + 1> hmin{};
    std::array<int, max_pattern> kmin{};
    std::array<int, max_pattern> rmin{};
    std::array<int, max_pattern> order{};
    std::array<int, max_pattern + 1> good_suffix{};
    std::array<std::array<int, max_pattern + 1>, 4> bad_character{};
    for (int shift = 1; shift <= m; ++shift) {
        int last_mismatch = shift - 1;
        for (int pos = shift; pos < m; ++pos)
            if (pattern[static_cast<std::size_t>(pos)] != pattern[static_cast<std::size_t>(pos - shift)]) last_mismatch = pos;
        hmin[static_cast<std::size_t>(shift)] = last_mismatch;
    }
    for (int shift = m; shift >= 1; --shift) {
        const int end = hmin[static_cast<std::size_t>(shift)];
        if (end != m - 1) kmin[static_cast<std::size_t>(end)] = shift;
    }
    int next_boundary = m;
    for (int end = m - 1; end >= 0; --end) {
        if (hmin[static_cast<std::size_t>(end + 1)] == end) next_boundary = end + 1;
        rmin[static_cast<std::size_t>(end)] = next_boundary;
    }

    order[0] = m - 1;
    int cursor = 0;
    for (int shift = 1; shift <= m; ++shift) {
        const int end = hmin[static_cast<std::size_t>(shift)];
        if (end != m - 1 && kmin[static_cast<std::size_t>(end)] == shift) {
            order[static_cast<std::size_t>(++cursor)] = end;
            good_suffix[static_cast<std::size_t>(cursor)] = shift;
        }
    }
    cursor = m - 1;
    for (int end = m - 2; end >= 0; --end) {
        if (kmin[static_cast<std::size_t>(end)] == 0) {
            order[static_cast<std::size_t>(cursor)] = end;
            good_suffix[static_cast<std::size_t>(cursor)] = rmin[static_cast<std::size_t>(end)];
            --cursor;
        }
    }
    good_suffix[static_cast<std::size_t>(m)] = rmin[0];

    for (int symbol = 0; symbol < 4; ++symbol) {
        for (int prior_shift = 1; prior_shift <= m; ++prior_shift) {
            const int boundary = m - prior_shift - 1;
            for (int shift = 1; shift <= m; ++shift) {
                if (shift < m && pattern[static_cast<std::size_t>(m - shift - 1)] != symbol) continue;
                if (shift <= boundary && pattern[static_cast<std::size_t>(m - shift - prior_shift - 1)] !=
                    pattern[static_cast<std::size_t>(boundary)]) continue;
                bad_character[static_cast<std::size_t>(symbol)][static_cast<std::size_t>(prior_shift)] = shift;
                break;
            }
        }
    }

    std::int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int start = 0, shift_state = m;
    const int last_start = n - m;
    while (start <= last_start) {
        while (start <= last_start && pattern[static_cast<std::size_t>(m - 1)] !=
               text[static_cast<std::size_t>(start + m - 1)]) {
            shift_state = bad_character[text[static_cast<std::size_t>(start + m - 1)]][static_cast<std::size_t>(shift_state)];
            start += shift_state;
        }
        if (start > last_start) break;
        int index = 1;
        while (index < m && pattern[static_cast<std::size_t>(order[static_cast<std::size_t>(index)])] ==
               text[static_cast<std::size_t>(start + order[static_cast<std::size_t>(index)])]) ++index;
        if (index == m) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
        }
        shift_state = good_suffix[static_cast<std::size_t>(index)];
        start += shift_state;
    }
    const std::uint64_t packed = (static_cast<std::uint64_t>(count) << 36) |
                                 (static_cast<std::uint64_t>(offset_sum) << 12) |
                                 static_cast<std::uint64_t>(offset_xor);
    return static_cast<std::int64_t>(packed);
}
