#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;
constexpr std::size_t max_states = 2 * max_pattern + 2;
constexpr std::size_t alphabet = 4;

struct SuffixAutomaton {
    std::array<std::array<std::int64_t, alphabet>, max_states> transition{};
    std::array<std::int64_t, max_states> suffix_link{};
    std::array<std::int64_t, max_states> max_length{};
    std::size_t state_count = 1;

    SuffixAutomaton() noexcept {
        for (auto &row : transition) row.fill(-1);
        suffix_link.fill(-1);
        max_length.fill(0);
    }

    std::int64_t extend(std::int64_t last, std::size_t symbol) noexcept {
        if (state_count >= max_states) return -1;
        const std::size_t current = state_count++;
        max_length[current] = max_length[static_cast<std::size_t>(last)] + 1;
        std::int64_t state = last;
        while (state >= 0 && transition[static_cast<std::size_t>(state)][symbol] < 0) {
            transition[static_cast<std::size_t>(state)][symbol] = static_cast<std::int64_t>(current);
            state = suffix_link[static_cast<std::size_t>(state)];
        }
        if (state < 0) {
            suffix_link[current] = 0;
        } else {
            const auto target = transition[static_cast<std::size_t>(state)][symbol];
            if (max_length[static_cast<std::size_t>(state)] + 1 ==
                max_length[static_cast<std::size_t>(target)]) {
                suffix_link[current] = target;
            } else {
                if (state_count >= max_states) return -1;
                const std::size_t clone = state_count++;
                max_length[clone] = max_length[static_cast<std::size_t>(state)] + 1;
                suffix_link[clone] = suffix_link[static_cast<std::size_t>(target)];
                transition[clone] = transition[static_cast<std::size_t>(target)];
                while (state >= 0 &&
                       transition[static_cast<std::size_t>(state)][symbol] == target) {
                    transition[static_cast<std::size_t>(state)][symbol] =
                        static_cast<std::int64_t>(clone);
                    state = suffix_link[static_cast<std::size_t>(state)];
                }
                suffix_link[static_cast<std::size_t>(target)] = static_cast<std::int64_t>(clone);
                suffix_link[current] = static_cast<std::int64_t>(clone);
            }
        }
        return static_cast<std::int64_t>(current);
    }
};

std::int64_t search(const SuffixAutomaton &sam, const std::int64_t *text,
                    std::size_t n, std::size_t m) noexcept {
    std::size_t state = 0;
    std::int64_t matched = 0, count = 0, sum = 0, xor_offsets = 0;
    for (std::size_t position = 0; position < n; ++position) {
        const auto symbol = static_cast<std::size_t>(text[position]);
        auto target = sam.transition[state][symbol];
        if (target >= 0) {
            ++matched;
            state = static_cast<std::size_t>(target);
        } else {
            while (state != 0 && sam.transition[state][symbol] < 0)
                state = static_cast<std::size_t>(sam.suffix_link[state]);
            target = sam.transition[state][symbol];
            if (target >= 0) {
                matched = sam.max_length[state] + 1;
                state = static_cast<std::size_t>(target);
            } else {
                matched = 0;
                state = 0;
            }
        }
        if (static_cast<std::size_t>(matched) == m) {
            const auto start = static_cast<std::int64_t>(position + 1 - m);
            ++count;
            sum += start;
            xor_offsets ^= start;
        }
    }
    return (count << 36) | (sum << 12) | xor_offsets;
}
}

extern "C" std::int64_t forward_dawg_matching(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto nv = input[0], mv = input[1];
    if (nv < 0 || nv > static_cast<std::int64_t>(max_text) ||
        mv < 1 || mv > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n = static_cast<std::size_t>(nv), m = static_cast<std::size_t>(mv);
    if (length != 2 + n + m) return -1;
    std::array<std::int64_t, max_pattern> pattern{};
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= static_cast<std::int64_t>(alphabet)) return -1;
    for (std::size_t i = 0; i < m; ++i) pattern[i] = input[2 + n + i];
    SuffixAutomaton sam;
    std::int64_t last = 0;
    for (std::size_t i = 0; i < m; ++i) {
        last = sam.extend(last, static_cast<std::size_t>(pattern[i]));
        if (last < 0) return -1;
    }
    return search(sam, input + 2, n, m);
}
