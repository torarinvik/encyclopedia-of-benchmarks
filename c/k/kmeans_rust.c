#include <stddef.h>
#include <stdint.h>

#define MIN_POINTS INT64_C(2)
#define MAX_POINTS INT64_C(8)
#define MAX_MOVES 256

static void assign_labels(const double *points, size_t n, const double centers[2], int64_t *labels)
{
    for (size_t i = 0; i < n; ++i) {
        const double d0 = points[i] - centers[0];
        const double d1 = points[i] - centers[1];
        labels[i] = d1 * d1 < d0 * d0 ? 1 : 0;
    }
}

int64_t kmeans_rust(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 10) return -1;
    const int64_t n_value = input[0];
    if (n_value < MIN_POINTS || n_value > MAX_POINTS || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    double points[MAX_POINTS];
    for (size_t i = 0; i < n; ++i) {
        const int64_t coordinate = input[i + 1];
        if (coordinate < -16 || coordinate > 16 || (i > 0 && input[i] >= coordinate)) return -1;
        points[i] = (double)coordinate;
    }

    double centers[2] = {points[0], points[n / 2]};
    int64_t labels[MAX_POINTS] = {0};
    assign_labels(points, n, centers, labels);
    for (size_t move = 0; move < MAX_MOVES; ++move) {
        double sums[2] = {0.0, 0.0};
        size_t counts[2] = {0, 0};
        for (size_t i = 0; i < n; ++i) {
            const size_t group = (size_t)labels[i];
            sums[group] += points[i];
            ++counts[group];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        centers[0] = sums[0] / (double)counts[0];
        centers[1] = sums[1] / (double)counts[1];

        int64_t next_labels[MAX_POINTS];
        assign_labels(points, n, centers, next_labels);
        int unchanged = 1;
        for (size_t i = 0; i < n; ++i)
            if (next_labels[i] != labels[i]) unchanged = 0;
        if (unchanged) {
            int64_t packed = 0;
            for (size_t i = 0; i < n; ++i) packed |= next_labels[i] << i;
            return packed;
        }
        for (size_t i = 0; i < n; ++i) labels[i] = next_labels[i];
    }
    return -2;
}
