// Uncompiled and unexecuted weighted-binary-search path-selection draft.
#include <cstddef>
#include <cstdint>

namespace {
struct State { std::int64_t score; int count; };
State best(State a, State b) {
    return a.score > b.score || (a.score == b.score && a.count >= b.count) ? a : b;
}
State penalized(const std::int64_t* weights, std::size_t n, std::int64_t penalty) {
    State two{0,0}, one{0,0};
    for (std::size_t i = 0; i < n; ++i) {
        State take{two.score + weights[i] - penalty, two.count + 1};
        State current = best(one, take);
        two = one; one = current;
    }
    return one;
}
}

extern "C" std::int64_t wqs_path_independent_set(const std::int64_t* input,
                                                  std::size_t length) {
    constexpr std::int64_t invalid = -1000000000;
    if (!input || length < 2 || length > 130) return invalid;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > (input[0]+1)/2) return invalid;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n+2) return invalid;
    for (std::size_t i = 0; i < n; ++i)
        if (input[2+i] < -1000 || input[2+i] > 1000) return invalid;
    std::int64_t low = -256001, high = 256001;
    while (low < high) {
        const auto middle = low + (high-low+1)/2;
        if (penalized(input+2, n, middle).count >= input[1]) low = middle;
        else high = middle-1;
    }
    return penalized(input+2, n, low).score + low*input[1];
}
