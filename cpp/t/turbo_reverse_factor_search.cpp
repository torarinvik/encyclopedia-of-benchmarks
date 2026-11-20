#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;
constexpr std::size_t max_states = 2 * max_pattern + 2;
constexpr std::size_t alphabet = 4;
constexpr std::size_t root = 0;
constexpr std::size_t artificial = 1;

struct Automaton {
    std::array<std::array<std::int64_t, alphabet>, max_states> transition{};
    std::array<std::array<std::int64_t, alphabet>, max_states> displacement{};
    std::array<std::int64_t, max_states> suffix_link{};
    std::array<std::int64_t, max_states> max_length{};
    std::array<std::int64_t, max_states> position{};
    std::array<std::int64_t, max_states> terminal{};
    std::size_t state_count = 2;

    Automaton() noexcept {
        for (auto &row : transition) row.fill(-1);
        for (auto &row : displacement) row.fill(0);
        suffix_link.fill(-1);
        max_length.fill(0);
        position.fill(0);
        terminal.fill(0);
        suffix_link[root] = static_cast<std::int64_t>(artificial);
    }

    bool build(const std::array<std::int64_t, max_pattern> &pattern,
               std::size_t m) noexcept {
        std::size_t last = root;
        for (std::size_t offset = 0; offset < m; ++offset) {
            const auto symbol = static_cast<std::size_t>(pattern[m - 1 - offset]);
            if (state_count >= max_states) return false;
            const std::size_t current = state_count++;
            max_length[current] = max_length[last] + 1;
            position[current] = position[last] + 1;
            std::int64_t state = static_cast<std::int64_t>(last);
            while (state != static_cast<std::int64_t>(root) &&
                   transition[static_cast<std::size_t>(state)][symbol] < 0) {
                transition[static_cast<std::size_t>(state)][symbol] =
                    static_cast<std::int64_t>(current);
                displacement[static_cast<std::size_t>(state)][symbol] =
                    position[current] - position[static_cast<std::size_t>(state)] - 1;
                state = suffix_link[static_cast<std::size_t>(state)];
            }
            const auto target = transition[static_cast<std::size_t>(state)][symbol];
            if (target < 0) {
                transition[root][symbol] = static_cast<std::int64_t>(current);
                displacement[root][symbol] = position[current] - position[root] - 1;
                suffix_link[current] = static_cast<std::int64_t>(root);
            } else if (max_length[static_cast<std::size_t>(state)] + 1 ==
                       max_length[static_cast<std::size_t>(target)]) {
                suffix_link[current] = target;
            } else {
                if (state_count >= max_states) return false;
                const std::size_t clone = state_count++;
                suffix_link[clone] = suffix_link[static_cast<std::size_t>(target)];
                max_length[clone] = max_length[static_cast<std::size_t>(state)] + 1;
                position[clone] = position[static_cast<std::size_t>(target)];
                terminal[clone] = terminal[static_cast<std::size_t>(target)];
                transition[clone] = transition[static_cast<std::size_t>(target)];
                displacement[clone] = displacement[static_cast<std::size_t>(target)];
                suffix_link[static_cast<std::size_t>(target)] =
                    static_cast<std::int64_t>(clone);
                suffix_link[current] = static_cast<std::int64_t>(clone);
                while (state != static_cast<std::int64_t>(artificial)) {
                    const auto old_target =
                        transition[static_cast<std::size_t>(state)][symbol];
                    if (old_target < 0 ||
                        max_length[static_cast<std::size_t>(old_target)] < max_length[clone]) break;
                    displacement[static_cast<std::size_t>(state)][symbol] =
                        position[static_cast<std::size_t>(old_target)] -
                        position[static_cast<std::size_t>(state)] - 1;
                    transition[static_cast<std::size_t>(state)][symbol] =
                        static_cast<std::int64_t>(clone);
                    state = suffix_link[static_cast<std::size_t>(state)];
                }
            }
            last = current;
        }
        terminal[last] = 1;
        while (last != root) {
            last = static_cast<std::size_t>(suffix_link[last]);
            terminal[last] = 1;
        }
        return true;
    }
};

void mp_next(const std::array<std::int64_t, max_pattern> &pattern,
             std::size_t m, std::array<std::int64_t, max_pattern + 1> &next) noexcept {
    std::int64_t i = 0, border = -1;
    next[0] = -1;
    while (static_cast<std::size_t>(i) < m) {
        while (border >= 0 && pattern[static_cast<std::size_t>(i)] !=
                                  pattern[static_cast<std::size_t>(border)])
            border = next[static_cast<std::size_t>(border)];
        ++i;
        ++border;
        next[static_cast<std::size_t>(i)] = border;
    }
}

std::int64_t search(const Automaton &aut, const std::int64_t *text,
                    std::size_t n, std::size_t m,
                    const std::array<std::int64_t, max_pattern + 1> &mp) noexcept {
    if (n < m) return 0;
    const auto period = static_cast<std::int64_t>(m) - mp[m];
    std::int64_t count = 0, sum = 0, xor_offsets = 0;
    std::size_t start = 0;
    std::int64_t previous_shift = static_cast<std::int64_t>(m);
    while (start <= n - m) {
        std::int64_t index = static_cast<std::int64_t>(m) - 1;
        std::size_t state = root;
        std::int64_t boundary = static_cast<std::int64_t>(m) - 1 - previous_shift;
        const auto prefix_length = static_cast<std::int64_t>(m) - previous_shift;
        const auto prefix_period = previous_shift != static_cast<std::int64_t>(m)
            ? prefix_length - mp[static_cast<std::size_t>(prefix_length)] : 0;
        std::int64_t shift = static_cast<std::int64_t>(m);
        std::int64_t displacement_sum = 0;
        while (index > boundary) {
            const auto symbol = static_cast<std::size_t>(text[start + static_cast<std::size_t>(index)]);
            const auto target = aut.transition[state][symbol];
            if (target < 0) break;
            displacement_sum += aut.displacement[state][symbol];
            state = static_cast<std::size_t>(target);
            if (aut.terminal[state]) shift = index;
            --index;
        }
        if (index <= boundary) {
            if (displacement_sum == 0) {
                ++count;
                sum += static_cast<std::int64_t>(start);
                xor_offsets ^= static_cast<std::int64_t>(start);
                shift = period;
            } else {
                const auto half = (boundary + 1) / 2;
                if (prefix_period <= half) {
                    boundary -= prefix_period;
                    while (index > boundary) {
                        const auto symbol = static_cast<std::size_t>(text[start + static_cast<std::size_t>(index)]);
                        const auto target = aut.transition[state][symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state][symbol];
                        state = static_cast<std::size_t>(target);
                        if (aut.terminal[state]) shift = index;
                        --index;
                    }
                    if (index <= boundary) shift = displacement_sum;
                } else {
                    boundary = boundary - half - 1;
                    while (index > boundary) {
                        const auto symbol = static_cast<std::size_t>(text[start + static_cast<std::size_t>(index)]);
                        const auto target = aut.transition[state][symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state][symbol];
                        state = static_cast<std::size_t>(target);
                        if (aut.terminal[state]) shift = index;
                        --index;
                    }
                }
            }
        }
        if (shift <= 0) return -1;
        start += static_cast<std::size_t>(shift);
        previous_shift = shift;
    }
    return (count << 36) | (sum << 12) | xor_offsets;
}
}

extern "C" std::int64_t turbo_reverse_factor_search(const std::int64_t *input,
                                                      std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto nv = input[0], mv = input[1];
    if (nv < 0 || nv > static_cast<std::int64_t>(max_text) ||
        mv < 1 || mv > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n = static_cast<std::size_t>(nv), m = static_cast<std::size_t>(mv);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= static_cast<std::int64_t>(alphabet)) return -1;
    std::array<std::int64_t, max_pattern> pattern{};
    for (std::size_t i = 0; i < m; ++i) pattern[i] = input[2 + n + i];
    Automaton aut;
    if (!aut.build(pattern, m)) return -1;
    std::array<std::int64_t, max_pattern + 1> mp{};
    mp_next(pattern, m, mp);
    return search(aut, input + 2, n, m, mp);
}
