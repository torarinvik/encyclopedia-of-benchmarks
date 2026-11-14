// Uncompiled and unexecuted Cartesian-tree histogram draft.
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t cartesian_histogram_area(const std::int64_t* heights,
                                                  std::size_t length) {
    constexpr auto invalid = std::numeric_limits<std::int64_t>::min();
    if (length == 0) return 0;
    if (!heights || length > 64) return invalid;
    for (std::size_t i = 0; i < length; ++i)
        if (heights[i] < 0 || heights[i] > 1000000) return invalid;
    int left[64], right[64], stack[64], order[64], sizes[64]{};
    for (std::size_t i = 0; i < length; ++i) left[i] = right[i] = -1;
    std::size_t top = 0;
    for (std::size_t i = 0; i < length; ++i) {
        int last = -1;
        while (top && heights[stack[top-1]] > heights[i]) last = stack[--top];
        if (top) right[stack[top-1]] = static_cast<int>(i);
        left[i] = last;
        stack[top++] = static_cast<int>(i);
    }
    const int root = stack[0];
    top = 0;
    std::size_t used = 0;
    stack[top++] = root;
    while (top) {
        const int node = stack[--top];
        order[used++] = node;
        if (left[node] >= 0) stack[top++] = left[node];
        if (right[node] >= 0) stack[top++] = right[node];
    }
    std::int64_t best = 0;
    while (used) {
        const int node = order[--used];
        sizes[node] = 1 + (left[node] < 0 ? 0 : sizes[left[node]])
                        + (right[node] < 0 ? 0 : sizes[right[node]]);
        const auto area = heights[node] * sizes[node];
        if (area > best) best = area;
    }
    return best;
}
