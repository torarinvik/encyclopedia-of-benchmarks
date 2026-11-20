#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;
constexpr std::size_t max_states = 2 * max_pattern + 1;
}

extern "C" std::int64_t reverse_factor_search(const std::int64_t* input,
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

    std::array<std::array<int, 4>, max_states> transitions{};
    std::array<int, max_states> suffix_link{};
    std::array<int, max_states> max_length{};
    std::array<bool, max_states> terminal{};
    for (std::size_t state = 0; state < max_states; ++state) {
        suffix_link[state] = -1;
        transitions[state].fill(-1);
    }
    int state_count = 1, last = 0;
    for (int pos = 0; pos < m; ++pos) {
        const int symbol = pattern[static_cast<std::size_t>(m - 1 - pos)];
        const int current = state_count++;
        max_length[static_cast<std::size_t>(current)] = max_length[static_cast<std::size_t>(last)] + 1;
        int predecessor = last;
        while (predecessor >= 0 && transitions[static_cast<std::size_t>(predecessor)][static_cast<std::size_t>(symbol)] < 0) {
            transitions[static_cast<std::size_t>(predecessor)][static_cast<std::size_t>(symbol)] = current;
            predecessor = suffix_link[static_cast<std::size_t>(predecessor)];
        }
        if (predecessor < 0) {
            suffix_link[static_cast<std::size_t>(current)] = 0;
        } else {
            const int target = transitions[static_cast<std::size_t>(predecessor)][static_cast<std::size_t>(symbol)];
            if (max_length[static_cast<std::size_t>(predecessor)] + 1 == max_length[static_cast<std::size_t>(target)]) {
                suffix_link[static_cast<std::size_t>(current)] = target;
            } else {
                const int clone = state_count++;
                transitions[static_cast<std::size_t>(clone)] = transitions[static_cast<std::size_t>(target)];
                max_length[static_cast<std::size_t>(clone)] = max_length[static_cast<std::size_t>(predecessor)] + 1;
                suffix_link[static_cast<std::size_t>(clone)] = suffix_link[static_cast<std::size_t>(target)];
                while (predecessor >= 0 && transitions[static_cast<std::size_t>(predecessor)][static_cast<std::size_t>(symbol)] == target) {
                    transitions[static_cast<std::size_t>(predecessor)][static_cast<std::size_t>(symbol)] = clone;
                    predecessor = suffix_link[static_cast<std::size_t>(predecessor)];
                }
                suffix_link[static_cast<std::size_t>(target)] = clone;
                suffix_link[static_cast<std::size_t>(current)] = clone;
            }
        }
        last = current;
    }
    for (int state = last; state >= 0; state = suffix_link[static_cast<std::size_t>(state)])
        terminal[static_cast<std::size_t>(state)] = true;

    std::int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int period = m;
    int start = 0;
    while (start <= n - m) {
        int index = m - 1;
        int state = 0;
        int shift = m;
        while (start + index >= 0) {
            const int target = transitions[static_cast<std::size_t>(state)][text[static_cast<std::size_t>(start + index)]];
            if (target < 0) break;
            state = target;
            if (terminal[static_cast<std::size_t>(state)]) {
                period = shift;
                shift = index;
            }
            --index;
        }
        if (index < 0) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            shift = period;
        }
        start += shift;
    }
    const std::uint64_t packed = (static_cast<std::uint64_t>(count) << 36) |
                                 (static_cast<std::uint64_t>(offset_sum) << 12) |
                                 static_cast<std::uint64_t>(offset_xor);
    return static_cast<std::int64_t>(packed);
}
