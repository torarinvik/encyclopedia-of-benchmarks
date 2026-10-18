#include <stddef.h>
#include <stdint.h>

#define MIN_POINTS INT64_C(3)
#define MAX_POINTS INT64_C(8)
#define MIN_COORDINATE INT64_C(-16)
#define MAX_COORDINATE INT64_C(16)
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

int64_t k_means_julia(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 10) return -1;
    const int64_t n_value = input[0];
    if (n_value < MIN_POINTS || n_value > MAX_POINTS || length != (size_t)n_value + 1) return -1;

    const size_t n = (size_t)n_value;
    double points[MAX_POINTS];
    for (size_t i = 0; i < n; ++i) {
        const int64_t coordinate = input[i + 1];
        if (coordinate < MIN_COORDINATE || coordinate > MAX_COORDINATE ||
            (i > 0 && input[i] >= coordinate)) return -1;
        points[i] = (double)coordinate;
    }

    /* Julia's one-based floor(1 + n/2) is zero-based index floor(n/2). */
    double centers[2] = {points[0], points[n / 2]};
    for (size_t move = 0; move < MAX_MOVES; ++move) {
        double sums[2] = {0.0, 0.0};
        size_t counts[2] = {0, 0};
        for (size_t i = 0; i < n; ++i) {
            const double d0 = points[i] - centers[0];
            const double d1 = points[i] - centers[1];
            const double distance0 = d0 * d0;
            const double distance1 = d1 * d1;
            const size_t group = distance1 < distance0 ? 1U : 0U;
            sums[group] += points[i];
            ++counts[group];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;

        const double moved[2] = {
            sums[0] / (double)counts[0],
            sums[1] / (double)counts[1],
        };
        if (moved[0] == centers[0] && moved[1] == centers[1])
            return pack_centers(moved[0], moved[1]);
        centers[0] = moved[0];
        centers[1] = moved[1];
    }
    return -2;
}
