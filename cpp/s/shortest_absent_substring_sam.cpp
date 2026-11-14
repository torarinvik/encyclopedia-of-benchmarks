#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct State { std::array<int,4> next{-1,-1,-1,-1}; int link = -1, len = 0; };
}
extern "C" std::int64_t shortest_absent_substring_sam(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > 66 || input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 64) return -1;
    const int alphabet = static_cast<int>(input[0]), n = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2+n)) return -1;
    for (int i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] >= alphabet) return -1;
    std::array<State,129> states{};
    int size = 1, last = 0;
    for (int i = 0; i < n; ++i) {
        const int symbol = static_cast<int>(input[2+i]), current = size++;
        int p = last; states[current].len = states[last].len+1;
        while (p >= 0 && states[p].next[symbol] < 0) { states[p].next[symbol] = current; p = states[p].link; }
        if (p < 0) states[current].link = 0;
        else {
            const int q = states[p].next[symbol];
            if (states[p].len+1 == states[q].len) states[current].link = q;
            else {
                const int clone = size++; states[clone] = states[q]; states[clone].len = states[p].len+1;
                while (p >= 0 && states[p].next[symbol] == q) { states[p].next[symbol] = clone; p = states[p].link; }
                states[q].link = states[current].link = clone;
            }
        }
        last = current;
    }
    std::array<int,65> counts{}; std::array<int,129> order{}, dp{};
    for (int s = 0; s < size; ++s) ++counts[states[s].len];
    for (int i = 1; i <= n; ++i) counts[i] += counts[i-1];
    for (int s = size-1; s >= 0; --s) order[--counts[states[s].len]] = s;
    for (int i = size-1; i >= 0; --i) {
        int s = order[i], best = 100;
        for (int a = 0; a < alphabet; ++a) {
            int child = states[s].next[a], candidate = child < 0 ? 1 : 1+dp[child];
            if (candidate < best) best = candidate;
        }
        dp[s] = best;
    }
    std::array<std::uint8_t,6> result{}; int count = 0, state = 0;
    while (state >= 0) for (int a = 0; a < alphabet; ++a) {
        int child = states[state].next[a];
        if ((child < 0 && dp[state] == 1) || (child >= 0 && dp[state] == 1+dp[child])) {
            result[count++] = static_cast<std::uint8_t>(a); state = child; break;
        }
    }
    if (!output || capacity < static_cast<std::size_t>(count)) return -2;
    for (int i = 0; i < count; ++i) output[i] = result[i];
    return count;
}
