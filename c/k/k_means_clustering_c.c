#include <stddef.h>
#include <stdint.h>

#define MIN_POINTS INT64_C(3)
#define MAX_POINTS INT64_C(8)
#define MAX_MOVES 64
#define CENTER_SCALE 256.0
#define CENTER_BIAS INT64_C(4097)
#define CENTER_BASE INT64_C(8194)

static int64_t pack_centers(double first, double second)
{
    const int64_t first_code = (int64_t)(first * CENTER_SCALE) + CENTER_BIAS;
    const int64_t second_code = (int64_t)(second * CENTER_SCALE) + CENTER_BIAS;
    if (first_code < 1 || first_code > 8193 || second_code < 1 || second_code > 8193) return -1;
    return first_code * CENTER_BASE + second_code;
}

int64_t k_means_clustering_c(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 18) return -1;
    const int64_t n_value = input[0];
    if (n_value < MIN_POINTS || n_value > MAX_POINTS || length != 1 + 2 * (size_t)n_value) return -1;
    const size_t n = (size_t)n_value;
    const int64_t *initial_labels = input + 1;
    const int64_t *raw_points = input + 1 + n;
    int64_t labels[MAX_POINTS];
    int has_zero = 0, has_one = 0;
    for (size_t i = 0; i < n; ++i) {
        if (initial_labels[i] != 0 && initial_labels[i] != 1) return -1;
        labels[i] = initial_labels[i];
        has_zero |= labels[i] == 0;
        has_one |= labels[i] == 1;
        if (raw_points[i] < -16 || raw_points[i] > 16 ||
            (i > 0 && raw_points[i - 1] >= raw_points[i])) return -1;
    }
    if (!has_zero || !has_one) return -1;

    for (size_t move = 0; move < MAX_MOVES; ++move) {
        double sums[2] = {0.0, 0.0};
        size_t counts[2] = {0, 0};
        for (size_t i = 0; i < n; ++i) {
            const size_t group = (size_t)labels[i];
            sums[group] += (double)raw_points[i];
            ++counts[group];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        const double centers[2] = {
            sums[0] / (double)counts[0],
            sums[1] / (double)counts[1],
        };

        size_t changed = 0;
        int64_t next_labels[MAX_POINTS];
        for (size_t i = 0; i < n; ++i) {
            const double d0 = (double)raw_points[i] - centers[0];
            const double d1 = (double)raw_points[i] - centers[1];
            const size_t group = d1 * d1 < d0 * d0 ? 1U : 0U;
            next_labels[i] = (int64_t)group;
            changed += group != (size_t)labels[i];
        }
        for (size_t i = 0; i < n; ++i) labels[i] = next_labels[i];
        if (changed == 0) return pack_centers(centers[0], centers[1]);
    }
    return -2;
}
