#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct State { std::array<int,95> next; int link = -1, len = 0; State() { next.fill(-1); } };
}
extern "C" std::int64_t longest_common_substring_sam(const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 2 || length > 515 || input[0] < 0 || input[0] > 256) return -1;
    const int n = static_cast<int>(input[0]);
    if (length < static_cast<std::size_t>(n+2) || input[n+1] < 0 || input[n+1] > 256) return -1;
    const int m = static_cast<int>(input[n+1]);
    if (length != static_cast<std::size_t>(n+m+2)) return -1;
    for (int i = 0; i < n; ++i) if (input[1+i] < 32 || input[1+i] > 126) return -1;
    for (int i = 0; i < m; ++i) if (input[n+2+i] < 32 || input[n+2+i] > 126) return -1;
    std::array<State, 513> states{}; int size = 1, last = 0;
    for (int i = 0; i < n; ++i) {
        int symbol = static_cast<int>(input[1+i])-32, current = size++, p = last;
        states[current].len = states[last].len+1;
        while (p >= 0 && states[p].next[symbol] < 0) { states[p].next[symbol] = current; p = states[p].link; }
        if (p < 0) states[current].link = 0;
        else {
            int q = states[p].next[symbol];
            if (states[p].len+1 == states[q].len) states[current].link = q;
            else {
                int clone = size++; states[clone] = states[q]; states[clone].len = states[p].len+1;
                while (p >= 0 && states[p].next[symbol] == q) { states[p].next[symbol] = clone; p = states[p].link; }
                states[q].link = states[current].link = clone;
            }
        }
        last = current;
    }
    int state = 0, matched = 0, best = 0;
    for (int i = 0; i < m; ++i) {
        int symbol = static_cast<int>(input[n+2+i])-32;
        while (state != 0 && states[state].next[symbol] < 0) { state = states[state].link; matched = states[state].len; }
        int next = states[state].next[symbol];
        if (next < 0) { state = 0; matched = 0; }
        else { state = next; ++matched; if (matched > best) best = matched; }
    }
    return best;
}
