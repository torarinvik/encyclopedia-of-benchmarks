#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 44
#define MAX_HOUSES 8
#define MAX_COLORS 4
#define MAX_TARGET 8
#define INF INT64_C(801)

static size_t state(size_t color, size_t groups) { return color * 9 + groups; }

int64_t paint_house_iii(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t m64 = input[0], n64 = input[1], target64 = input[2];
    if (m64 < 1 || m64 > MAX_HOUSES || n64 < 1 || n64 > MAX_COLORS
        || target64 < 1 || target64 > m64) return -1;
    const size_t m = (size_t)m64, n = (size_t)n64, target = (size_t)target64;
    if (length != 3 + m + m * n) return -1;
    const size_t houses_at = 3, costs_at = 3 + m;
    for (size_t i = 0; i < m; ++i)
        if (input[houses_at + i] < 0 || input[houses_at + i] > n64) return -1;
    for (size_t i = 0; i < m * n; ++i)
        if (input[costs_at + i] < 0 || input[costs_at + i] > 100) return -1;

    int64_t previous[45], current[45];
    for (size_t i = 0; i < 45; ++i) previous[i] = INF;
    const int64_t first = input[houses_at];
    for (size_t color = 1; color <= n; ++color) {
        if (first == 0 || first == (int64_t)color)
            previous[state(color, 1)] = first == 0 ? input[costs_at + color - 1] : 0;
    }

    for (size_t house = 1; house < m; ++house) {
        for (size_t i = 0; i < 45; ++i) current[i] = INF;
        const int64_t fixed = input[houses_at + house];
        for (size_t color = 1; color <= n; ++color) {
            if (fixed != 0 && fixed != (int64_t)color) continue;
            const int64_t paint_cost = fixed == 0
                ? input[costs_at + house * n + color - 1] : 0;
            for (size_t groups = 1; groups <= target; ++groups) {
                int64_t best = INF;
                for (size_t old_color = 1; old_color <= n; ++old_color) {
                    const size_t old_groups = groups - (old_color != color ? 1 : 0);
                    if (old_groups >= 1 && previous[state(old_color, old_groups)] < best)
                        best = previous[state(old_color, old_groups)];
                }
                if (best < INF) current[state(color, groups)] = best + paint_cost;
            }
        }
        for (size_t i = 0; i < 45; ++i) previous[i] = current[i];
    }
    int64_t answer = INF;
    for (size_t color = 1; color <= n; ++color)
        if (previous[state(color, target)] < answer) answer = previous[state(color, target)];
    return answer >= INF ? -1 : answer;
}
