#include <stddef.h>
#include <stdint.h>

enum { MIN_VERTICES = 3, MAX_VERTICES = 12, MAX_PARSEABLE_LENGTH = 26 };

static int64_t squared_length(const int64_t x[MAX_VERTICES],
                              const int64_t y[MAX_VERTICES],
                              size_t left, size_t right) {
    const int64_t dx = x[left] - x[right];
    const int64_t dy = y[left] - y[right];
    return dx * dx + dy * dy;
}

int64_t convex_polygon_minimax_length_triangulation(const int64_t *input, size_t length) {
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < MIN_VERTICES || count_value > MAX_VERTICES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1u + 2u * count) return -1;

    int64_t x[MAX_VERTICES] = {0};
    int64_t y[MAX_VERTICES] = {0};
    for (size_t vertex = 0u; vertex < count; ++vertex) {
        x[vertex] = input[1u + 2u * vertex];
        y[vertex] = input[2u + 2u * vertex];
        if (x[vertex] < -1000 || x[vertex] > 1000 || y[vertex] < -1000 || y[vertex] > 1000) return -1;
    }

    int64_t area_twice = 0;
    for (size_t vertex = 0u; vertex < count; ++vertex) {
        const size_t next = (vertex + 1u) % count;
        area_twice += x[vertex] * y[next] - y[vertex] * x[next];
    }
    if (area_twice == 0) return -1;
    const int64_t orientation = area_twice > 0 ? 1 : -1;
    for (size_t edge = 0u; edge < count; ++edge) {
        const size_t next = (edge + 1u) % count;
        const int64_t dx = x[next] - x[edge];
        const int64_t dy = y[next] - y[edge];
        for (size_t vertex = 0u; vertex < count; ++vertex) {
            if (vertex == edge || vertex == next) continue;
            const int64_t cross = dx * (y[vertex] - y[edge]) - dy * (x[vertex] - x[edge]);
            if (orientation * cross <= 0) return -1;
        }
    }

    int64_t best[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t left = 0u; left + 1u < count; ++left)
        best[left][left + 1u] = squared_length(x, y, left, left + 1u);
    for (size_t span = 2u; span < count; ++span) {
        for (size_t left = 0u; left + span < count; ++left) {
            const size_t right = left + span;
            const int64_t boundary = squared_length(x, y, left, right);
            int64_t optimum = INT64_MAX;
            for (size_t middle = left + 1u; middle < right; ++middle) {
                int64_t candidate = best[left][middle];
                if (best[middle][right] > candidate) candidate = best[middle][right];
                if (boundary > candidate) candidate = boundary;
                if (candidate < optimum) optimum = candidate;
            }
            best[left][right] = optimum;
        }
    }
    return best[0][count - 1u];
}
