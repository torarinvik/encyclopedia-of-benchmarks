#include <stddef.h>
#include <stdint.h>

#define MIN_POINTS INT64_C(2)
#define MAX_POINTS INT64_C(8)
#define MAX_MOVES 64
#define CENTER_SCALE 256.0f
#define CENTER_BIAS INT64_C(4097)
#define CENTER_BASE INT64_C(8194)

static int64_t pack_clusters(float first, float second, size_t count0, size_t count1)
{
    const int64_t first_code = (int64_t)(first * CENTER_SCALE) + CENTER_BIAS;
    const int64_t second_code = (int64_t)(second * CENTER_SCALE) + CENTER_BIAS;
    if (first_code < 1 || first_code > 8193 || second_code < 1 || second_code > 8193 ||
        count0 > 8 || count1 > 8) return -1;
    const int64_t pair = first_code * CENTER_BASE + second_code;
    return pair * 81 + (int64_t)count0 * 9 + (int64_t)count1;
}

int64_t k_means_clustering_zig(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 10) return -1;
    const int64_t n_value = input[0];
    if (n_value < MIN_POINTS || n_value > MAX_POINTS || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    float points[MAX_POINTS];
    for (size_t i = 0; i < n; ++i) {
        const int64_t coordinate = input[i + 1];
        if (coordinate < -16 || coordinate > 16 || (i > 0 && input[i] >= coordinate)) return -1;
        points[i] = (float)coordinate;
    }

    float centers[2] = {points[0], points[1]};
    size_t old_counts[2] = {0, 0};
    for (size_t move = 0; move < MAX_MOVES; ++move) {
        float sums[2] = {0.0f, 0.0f};
        size_t counts[2] = {0, 0};
        for (size_t i = 0; i < n; ++i) {
            const float d0 = points[i] - centers[0];
            const float d1 = centers[1] - points[i];
            const float distance0 = d0 * d0;
            const float distance1 = d1 * d1;
            const size_t group = distance1 < distance0 ? 1U : 0U;
            sums[group] += points[i];
            ++counts[group];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;

        const float moved[2] = {
            sums[0] / (float)counts[0],
            sums[1] / (float)counts[1],
        };
        if (moved[0] == centers[0] && moved[1] == centers[1] &&
            counts[0] == old_counts[0] && counts[1] == old_counts[1])
            return pack_clusters(moved[0], moved[1], counts[0], counts[1]);

        centers[0] = moved[0];
        centers[1] = moved[1];
        old_counts[0] = counts[0];
        old_counts[1] = counts[1];
    }
    return -2;
}
