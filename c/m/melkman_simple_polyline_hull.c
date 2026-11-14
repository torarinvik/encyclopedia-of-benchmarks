#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; } point;

static int64_t turn(const point *p, size_t a, size_t b, size_t c) {
    return (p[b].x-p[a].x)*(p[c].y-p[a].y) - (p[b].y-p[a].y)*(p[c].x-p[a].x);
}

int64_t melkman_simple_polyline_hull(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 7 || length > 66) return -1;
    int64_t raw = input[0];
    if (raw < 3 || raw > 32 || length != 1 + 2*(size_t)raw) return -1;
    size_t n = (size_t)raw;
    point p[32];
    for (size_t i = 0; i < n; ++i) {
        p[i].x = input[1+2*i]; p[i].y = input[2+2*i];
        if (p[i].x < -1000 || p[i].x > 1000 || p[i].y < -1000 || p[i].y > 1000) return -1;
    }
    int64_t initial = turn(p, 0, 1, 2);
    if (initial == 0) return -1;
    size_t deque[68];
    size_t first = 32, last = 35;
    deque[32] = 2; deque[35] = 2;
    deque[33] = initial > 0 ? 0 : 1;
    deque[34] = initial > 0 ? 1 : 0;
    for (size_t i = 3; i < n; ++i) {
        if (turn(p, deque[first], deque[first+1], i) > 0 &&
            turn(p, deque[last-1], deque[last], i) > 0) continue;
        while (last > first && turn(p, deque[first], deque[first+1], i) <= 0) ++first;
        if (last <= first || first == 0) return -1;
        deque[--first] = i;
        while (last > first && turn(p, deque[last-1], deque[last], i) <= 0) --last;
        if (last <= first || last + 1 >= 68) return -1;
        deque[++last] = i;
    }
    size_t count = last-first, start = 0;
    for (size_t i = 1; i < count; ++i) {
        point a = p[deque[first+i]], b = p[deque[first+start]];
        if (a.x < b.x || (a.x == b.x && a.y < b.y)) start = i;
    }
    size_t bytes = 8*count;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[256];
    for (size_t i = 0; i < count; ++i) {
        uint64_t index = deque[first+(start+i)%count];
        for (size_t b = 0; b < 8; ++b) staged[8*i+b] = (uint8_t)(index >> (8*b));
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
