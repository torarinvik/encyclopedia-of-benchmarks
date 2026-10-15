#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

void assign_ranks(const std::int64_t *data, std::size_t n, double *ranks) {
    std::size_t order[3];
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const std::size_t key = order[i];
        std::size_t j = i;
        while (j > 0 && data[order[j - 1]] > data[key]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    std::size_t i = 0;
    while (i < n) {
        std::size_t j = i;
        while (j < n - 1 && data[order[j + 1]] == data[order[i]]) ++j;
        const double rank = (static_cast<double>(i) + static_cast<double>(j)) / 2.0 + 1.0;
        for (std::size_t k = i; k <= j; ++k) ranks[order[k]] = rank;
        i = j + 1;
    }
}

double round_tenth_ties_even(double value) {
    const double scaled = value * 10.0;
    const double lower = std::floor(scaled);
    const double fraction = scaled - lower;
    double rounded = lower;
    if (fraction > 0.5 || (fraction == 0.5 && std::fmod(lower, 2.0) != 0.0)) rounded = lower + 1.0;
    return rounded / 10.0;
}
}

extern "C" double spearman_rank_correlation_coefficient(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 5) return invalid_result;
    const std::int64_t n_value = values[0];
    if (n_value < 2 || n_value > 3 || length != 1 + 2 * static_cast<std::size_t>(n_value)) return invalid_result;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::int64_t *x = values + 1;
    const std::int64_t *y = values + 1 + n;
    double rank_x[3], rank_y[3];
    for (std::size_t i = 0; i < n; ++i)
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return invalid_result;
    assign_ranks(x, n, rank_x);
    assign_ranks(y, n, rank_y);
    double d_squared = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const double difference = rank_x[i] - rank_y[i];
        d_squared += difference * difference;
    }
    const double rho = 1.0 - (6.0 * d_squared) / static_cast<double>(n * (n * n - 1));
    return round_tenth_ties_even(rho);
}
