// Independently authored draft; not compiled or run.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct State { std::array<int, 256> next; int link, length; std::int64_t paths; };
}

extern "C" std::int64_t suffix_automaton_kth_distinct_substring(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 3 || length > 259) return -1;
    const auto raw_n = input[0];
    auto k = input[1];
    if (raw_n < 1 || raw_n > 256 || length != static_cast<std::size_t>(raw_n) + 2 || k < 1) return -1;
    const int n = static_cast<int>(raw_n);
    for (int i = 0; i < n; ++i) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    std::array<State, 512> states;
    for (auto& s : states) { s.next.fill(-1); s.link = -1; s.length = 0; s.paths = 0; }
    int count = 1, last = 0;
    for (int i = 0; i < n; ++i) {
        const int symbol = static_cast<int>(input[i + 2]);
        const int current = count++;
        states[current].length = states[last].length + 1;
        int p = last;
        while (p >= 0 && states[p].next[symbol] < 0) {
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
                states[q].link = states[current].link = clone;
            }
        }
        last = current;
    }
    std::array<int, 257> buckets{};
    std::array<int, 512> order{};
    for (int i = 0; i < count; ++i) ++buckets[states[i].length];
    for (int i = 1; i <= n; ++i) buckets[i] += buckets[i - 1];
    for (int i = count - 1; i >= 0; --i) order[--buckets[states[i].length]] = i;
    for (int i = count - 1; i >= 0; --i) {
        auto& s = states[order[i]];
        for (int next : s.next) if (next >= 0) s.paths += 1 + states[next].paths;
    }
    if (k > states[0].paths) return -1;
    std::array<std::uint8_t, 256> result{};
    std::size_t used = 0;
    int state = 0;
    for (;;) {
        bool found = false;
        for (int c = 0; c < 256; ++c) {
            const int next = states[state].next[c];
            if (next < 0) continue;
            const auto group = 1 + states[next].paths;
            if (k > group) { k -= group; continue; }
            result[used++] = static_cast<std::uint8_t>(c);
            state = next; found = true; break;
        }
        if (!found) return -1;
        if (k == 1) break;
        --k;
    }
    if (!output || capacity < used) return -2;
    std::copy_n(result.begin(), used, output);
    return static_cast<std::int64_t>(used);
}
