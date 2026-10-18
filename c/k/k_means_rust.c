#include <stddef.h>
#include <stdint.h>

#define U53_MAX INT64_C(9007199254740991)
#define U53_DENOMINATOR 9007199254740992.0

int64_t k_means_rust(const int64_t *input, size_t length)
{
    if (input == NULL || length != 10 || input[0] != 4) return -1;
    const int64_t max_iter = input[1];
    if (max_iter < 1 || max_iter > 16) return -1;

    const int64_t draw_x[2] = {input[2], input[4]};
    if (input[3] != 0 || input[5] != 0 || draw_x[0] < 0 || draw_x[0] > U53_MAX ||
        draw_x[1] < 0 || draw_x[1] > U53_MAX || draw_x[0] == draw_x[1]) return -1;

    const int64_t *raw_points = input + 6;
    double points[4];
    for (size_t i = 0; i < 4; ++i) {
        if (raw_points[i] < -16 || raw_points[i] > 16 ||
            (i > 0 && raw_points[i - 1] >= raw_points[i])) return -1;
        points[i] = (double)raw_points[i];
    }
    if (raw_points[1] >= 0 || raw_points[2] <= 1) return -1;

    double centers[2][2] = {
        {(double)draw_x[0] / U53_DENOMINATOR, 0.0},
        {(double)draw_x[1] / U53_DENOMINATOR, 0.0},
    };
    int64_t labels[4] = {0, 0, 0, 0};
    for (int64_t pass = 0; pass < max_iter; ++pass) {
        double sums[2][2] = {{0.0, 0.0}, {0.0, 0.0}};
        size_t counts[2] = {0, 0};
        for (size_t i = 0; i < 4; ++i) {
            const double dx0 = points[i] - centers[0][0];
            const double dy0 = -centers[0][1];
            const double dx1 = points[i] - centers[1][0];
            const double dy1 = -centers[1][1];
            const double distance0 = dx0 * dx0 + dy0 * dy0;
            const double distance1 = dx1 * dx1 + dy1 * dy1;
            const size_t group = distance1 < distance0 ? 1U : 0U;
            labels[i] = (int64_t)group;
            sums[group][0] += points[i];
            ++counts[group];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        for (size_t group = 0; group < 2; ++group) {
            centers[group][0] = sums[group][0] / (double)counts[group];
            centers[group][1] = sums[group][1] / (double)counts[group];
        }
    }

    int64_t packed = 0;
    for (size_t i = 0; i < 4; ++i) packed |= labels[i] << i;
    return packed;
}
