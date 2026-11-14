// Uncompiled and unexecuted slope-trick bounded-change fitting draft.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <queue>
#include <vector>

extern "C" std::int64_t slope_trick_lipschitz_l1(const std::int64_t* input,
                                                  std::size_t length) {
    if (!input || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > 100) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n+2) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i+2] < 0 || input[i+2] > 100) return -1;
    std::priority_queue<std::int64_t> left;
    std::priority_queue<std::int64_t, std::vector<std::int64_t>, std::greater<std::int64_t>> right;
    std::int64_t left_shift = 0, right_shift = 0, answer = 0;
    for (std::size_t i = 0; i < n; ++i) {
        left_shift -= input[1];
        right_shift += input[1];
        const auto observation = input[i+2];
        left.push(observation-left_shift);
        right.push(observation-right_shift);
        const auto l = left.top()+left_shift;
        const auto r = right.top()+right_shift;
        if (l > r) {
            left.pop(); right.pop();
            answer += l-r;
            left.push(r-left_shift);
            right.push(l-right_shift);
        }
    }
    return answer;
}
