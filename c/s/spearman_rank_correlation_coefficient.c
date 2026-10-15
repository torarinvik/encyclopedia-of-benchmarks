#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_N 3

static void assign_ranks(const int64_t *data, size_t n, double *ranks)
{
    size_t order[MAX_N];
    for (size_t i = 0; i < n; ++i) order[i] = i;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && data[order[j - 1]] > data[key]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    size_t i = 0;
    while (i < n) {
        size_t j = i;
        while (j < n - 1 && data[order[j + 1]] == data[order[i]]) ++j;
        const double rank = ((double)i + (double)j) / 2.0 + 1.0;
        for (size_t k = i; k <= j; ++k) ranks[order[k]] = rank;
        i = j + 1;
    }
}

static double round_tenth_ties_even(double value)
{
    const double scaled = value * 10.0;
    const double lower = floor(scaled);
    const double fraction = scaled - lower;
    double rounded = lower;
    if (fraction > 0.5 || (fraction == 0.5 && fmod(lower, 2.0) != 0.0)) rounded = lower + 1.0;
    return rounded / 10.0;
}

double spearman_rank_correlation_coefficient(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5) return INVALID_RESULT;
    const int64_t n_value = values[0];
    if (n_value < 2 || n_value > MAX_N || length != 1 + 2 * (size_t)n_value) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    const int64_t *x = values + 1;
    const int64_t *y = values + 1 + n;
    double rank_x[MAX_N], rank_y[MAX_N];
    for (size_t i = 0; i < n; ++i)
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return INVALID_RESULT;
    assign_ranks(x, n, rank_x);
    assign_ranks(y, n, rank_y);
    double d_squared = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const double difference = rank_x[i] - rank_y[i];
        d_squared += difference * difference;
    }
    const double rho = 1.0 - (6.0 * d_squared) / (double)(n * (n * n - 1));
    return round_tenth_ties_even(rho);
}
