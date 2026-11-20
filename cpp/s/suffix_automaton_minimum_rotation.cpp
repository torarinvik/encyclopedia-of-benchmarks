// Uncompiled suffix-automaton minimum-rotation draft.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct State {
    std::array<int, 256> next;
    int link;
    int length;
};
}

extern "C" std::int64_t suffix_automaton_minimum_rotation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 258) return -1;
    const auto raw_n = input[0];
    if (raw_n < 1 || raw_n > 256 || length != static_cast<std::size_t>(raw_n) + 1) return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (!output || capacity < n) return -2;
    std::array<State, 1024> states;
    for (auto& state : states) { state.next.fill(-1); state.link = -1; state.length = 0; }
    int count = 1, last = 0;
    for (std::size_t i = 0; i < 2*n; ++i) {
        const int symbol = static_cast<int>(input[1+i%n]);
        const int current = count++;
        states[current].length = states[last].length + 1;
        int p = last;
        while (p >= 0 && states[p].next[symbol] == -1) {
            states[p].next[symbol] = current; p = states[p].link;
        }
        if (p < 0) states[current].link = 0;
        else {
            const int q = states[p].next[symbol];
            if (states[p].length + 1 == states[q].length) states[current].link = q;
            else {
                const int clone = count++;
                states[clone] = states[q];
                states[clone].length = states[p].length + 1;
                while (p >= 0 && states[p].next[symbol] == q) {
                    states[p].next[symbol] = clone; p = states[p].link;
                }
                states[q].link = clone; states[current].link = clone;
            }
        }
        last = current;
    }
    int state = 0;
    for (std::size_t i = 0; i < n; ++i) {
        int symbol = 0;
        while (states[state].next[symbol] < 0) ++symbol;
        output[i] = static_cast<std::uint8_t>(symbol);
        state = states[state].next[symbol];
    }
    return raw_n;
}
