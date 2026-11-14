#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

using Point = std::pair<int64_t, int64_t>;
static int64_t cross(const std::array<Point, 32>& p, size_t a, size_t b, size_t c) {
    return (p[b].first-p[a].first)*(p[c].second-p[a].second)
         - (p[b].second-p[a].second)*(p[c].first-p[a].first);
}

extern "C" int64_t melkman_simple_polyline_hull(const int64_t *input, size_t length,
                                                  uint8_t *output, size_t capacity) {
    if (!input || length < 7 || length > 66) return -1;
    const int64_t raw = input[0];
    if (raw < 3 || raw > 32 || length != 1 + 2*static_cast<size_t>(raw)) return -1;
    const size_t n = static_cast<size_t>(raw);
    std::array<Point, 32> points{};
    for (size_t i = 0; i < n; ++i) {
        auto x = input[1+2*i], y = input[2+2*i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        points[i] = {x,y};
    }
    const auto initial = cross(points, 0, 1, 2);
    if (initial == 0) return -1;
    std::array<size_t, 68> deque{};
    size_t first = 32, last = 35;
    deque[32] = deque[35] = 2;
    deque[33] = initial > 0 ? 0 : 1;
    deque[34] = initial > 0 ? 1 : 0;
    for (size_t i = 3; i < n; ++i) {
        if (cross(points, deque[first], deque[first+1], i) > 0 &&
            cross(points, deque[last-1], deque[last], i) > 0) continue;
        while (last > first && cross(points, deque[first], deque[first+1], i) <= 0) ++first;
        if (last <= first || first == 0) return -1;
        deque[--first] = i;
        while (last > first && cross(points, deque[last-1], deque[last], i) <= 0) --last;
        if (last <= first || last + 1 >= deque.size()) return -1;
        deque[++last] = i;
    }
    const size_t count = last-first;
    size_t start = 0;
    for (size_t i = 1; i < count; ++i)
        if (points[deque[first+i]] < points[deque[first+start]]) start = i;
    const size_t bytes = 8*count;
    if (!output || capacity < bytes) return -2;
    std::array<uint8_t, 256> staged{};
    for (size_t i = 0; i < count; ++i) {
        uint64_t index = deque[first+(start+i)%count];
        for (size_t b = 0; b < 8; ++b) staged[8*i+b] = static_cast<uint8_t>(index >> (8*b));
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<int64_t>(bytes);
}
