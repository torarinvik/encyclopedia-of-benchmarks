#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OBSERVATIONS = 128, MAX_GROUPS = 8;
constexpr double INVALID_RESULT = -1.0e300;

double safe_denominator(double value) noexcept
{
    constexpr double minimum = 1.0e-300;
    if (std::abs(value) >= minimum) return value;
    return value < 0.0 ? -minimum : minimum;
}

double log_gamma_lanczos(double value) noexcept
{
    const double z = value - 1.0;
    double sum = 0.99999999999980993;
    sum += 676.5203681218851 / (z + 1.0);
    sum += -1259.1392167224028 / (z + 2.0);
    sum += 771.32342877765313 / (z + 3.0);
    sum += -176.61502916214059 / (z + 4.0);
    sum += 12.507343278686905 / (z + 5.0);
    sum += -0.13857109526572012 / (z + 6.0);
    sum += 9.9843695780195716e-6 / (z + 7.0);
    sum += 1.5056327351493116e-7 / (z + 8.0);
    const double t = z + 7.5;
    return 0.91893853320467274178 + (z + 0.5) * std::log(t) - t + std::log(sum);
}

double beta_fraction(double a, double b, double x) noexcept
{
    constexpr double epsilon = 3.0e-14;
    const double qab = a + b, qap = a + 1.0, qam = a - 1.0;
    double c = 1.0;
    double d = safe_denominator(1.0 - qab * x / qap);
    d = 1.0 / d;
    double result = d;
    for (int m = 1; m <= 200; ++m) {
        const double md = static_cast<double>(m), m2 = 2.0 * md;
        double coefficient = md * (b - md) * x / ((qam + m2) * (a + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        result *= d * c;
        coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        const double change = d * c;
        result *= change;
        if (std::abs(change - 1.0) <= epsilon) break;
    }
    return result;
}

double regularized_beta(double x, double a, double b) noexcept
{
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    const double front = std::exp(a * std::log(x) + b * std::log(1.0 - x) +
                                  log_gamma_lanczos(a + b) - log_gamma_lanczos(a) - log_gamma_lanczos(b));
    if (x < (a + 1.0) / (a + b + 2.0)) return front * beta_fraction(a, b, x) / a;
    return 1.0 - front * beta_fraction(b, a, 1.0 - x) / b;
}
}

extern "C" double anova_oneway(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3) return INVALID_RESULT;
    const auto statistic = input[0], observation_count = input[1], group_count = input[2];
    if (statistic < 0 || statistic > 7 || observation_count <= group_count || observation_count > 128 ||
        group_count < 2 || group_count > 8 || length != 3 + 2 * static_cast<std::size_t>(observation_count)) return INVALID_RESULT;

    std::array<double, MAX_GROUPS> group_sums{};
    std::array<double, MAX_GROUPS> group_means{};
    std::array<std::int64_t, MAX_GROUPS> group_sizes{};
    std::array<std::int64_t, MAX_OBSERVATIONS> labels{};
    double total = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(observation_count); ++i) {
        const auto value = input[3 + i];
        const auto group = input[3 + static_cast<std::size_t>(observation_count) + i];
        if (value < -1'000'000 || value > 1'000'000 || group < 0 || group >= group_count) return INVALID_RESULT;
        labels[i] = group;
        group_sums[static_cast<std::size_t>(group)] += static_cast<double>(value);
        ++group_sizes[static_cast<std::size_t>(group)];
        total += static_cast<double>(value);
    }
    for (std::size_t group = 0; group < static_cast<std::size_t>(group_count); ++group) {
        if (group_sizes[group] == 0) return INVALID_RESULT;
        group_means[group] = group_sums[group] / static_cast<double>(group_sizes[group]);
    }
    const double grand_mean = total / static_cast<double>(observation_count);
    double ss_between = 0.0;
    for (std::size_t group = 0; group < static_cast<std::size_t>(group_count); ++group) {
        const double difference = group_means[group] - grand_mean;
        ss_between += static_cast<double>(group_sizes[group]) * difference * difference;
    }
    double ss_within = 0.0;
    for (std::size_t group = 0; group < static_cast<std::size_t>(group_count); ++group) {
        for (std::size_t i = 0; i < static_cast<std::size_t>(observation_count); ++i) {
            if (labels[i] == static_cast<std::int64_t>(group)) {
                const double difference = static_cast<double>(input[3 + i]) - group_means[group];
                ss_within += difference * difference;
            }
        }
    }
    if (!(ss_within > 0.0)) return INVALID_RESULT;
    const double df_between = static_cast<double>(group_count - 1);
    const double df_within = static_cast<double>(observation_count - group_count);
    const double ms_between = ss_between / df_between;
    const double ms_within = ss_within / df_within;
    const double f_statistic = ms_between / ms_within;
    const double beta_x = df_within / (df_within + df_between * f_statistic);
    const double p_value = regularized_beta(beta_x, df_within / 2.0, df_between / 2.0);
    const std::array<double, 8> outputs = {df_between, df_within, ss_between, ss_within,
                                           ms_between, ms_within, f_statistic, p_value};
    return outputs[static_cast<std::size_t>(statistic)];
}
