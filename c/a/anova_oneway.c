#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 128
#define MAX_GROUPS 8
#define INVALID_RESULT (-1.0e300)

static double abs_f64(double value)
{
    return value < 0.0 ? -value : value;
}

static double safe_denominator(double value)
{
    const double minimum = 1.0e-300;
    if (abs_f64(value) >= minimum) return value;
    return value < 0.0 ? -minimum : minimum;
}

static double log_gamma_lanczos(double value)
{
    double z = value - 1.0;
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
    return 0.91893853320467274178 + (z + 0.5) * log(t) - t + log(sum);
}

static double beta_fraction(double a, double b, double x)
{
    const double epsilon = 3.0e-14;
    const double qab = a + b;
    const double qap = a + 1.0;
    const double qam = a - 1.0;
    double c = 1.0;
    double d = safe_denominator(1.0 - qab * x / qap);
    d = 1.0 / d;
    double result = d;
    for (int m = 1; m <= 200; ++m) {
        const double m_value = (double)m;
        const double m2 = 2.0 * m_value;
        double coefficient = m_value * (b - m_value) * x / ((qam + m2) * (a + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        result *= d * c;
        coefficient = -(a + m_value) * (qab + m_value) * x / ((a + m2) * (qap + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        const double change = d * c;
        result *= change;
        if (abs_f64(change - 1.0) <= epsilon) break;
    }
    return result;
}

static double regularized_beta(double x, double a, double b)
{
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    const double front = exp(a * log(x) + b * log(1.0 - x) +
                             log_gamma_lanczos(a + b) - log_gamma_lanczos(a) - log_gamma_lanczos(b));
    if (x < (a + 1.0) / (a + b + 2.0)) return front * beta_fraction(a, b, x) / a;
    return 1.0 - front * beta_fraction(b, a, 1.0 - x) / b;
}

double anova_oneway(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return INVALID_RESULT;
    const int64_t statistic = input[0];
    const int64_t observation_count = input[1];
    const int64_t group_count = input[2];
    if (statistic < 0 || statistic > 7 || observation_count <= group_count ||
        observation_count > MAX_OBSERVATIONS || group_count < 2 || group_count > MAX_GROUPS ||
        length != 3 + 2 * (size_t)observation_count) return INVALID_RESULT;

    double group_sums[MAX_GROUPS] = {0.0};
    double group_means[MAX_GROUPS] = {0.0};
    int64_t group_sizes[MAX_GROUPS] = {0};
    int64_t labels[MAX_OBSERVATIONS];
    double total = 0.0;
    for (size_t i = 0; i < (size_t)observation_count; ++i) {
        const int64_t value = input[3 + i];
        const int64_t group = input[3 + (size_t)observation_count + i];
        if (value < -1000000 || value > 1000000 || group < 0 || group >= group_count) return INVALID_RESULT;
        labels[i] = group;
        group_sums[group] += (double)value;
        group_sizes[group]++;
        total += (double)value;
    }

    for (size_t group = 0; group < (size_t)group_count; ++group) {
        if (group_sizes[group] == 0) return INVALID_RESULT;
        group_means[group] = group_sums[group] / (double)group_sizes[group];
    }
    const double grand_mean = total / (double)observation_count;
    double ss_between = 0.0;
    for (size_t group = 0; group < (size_t)group_count; ++group) {
        const double difference = group_means[group] - grand_mean;
        ss_between += (double)group_sizes[group] * difference * difference;
    }
    double ss_within = 0.0;
    for (size_t group = 0; group < (size_t)group_count; ++group) {
        for (size_t i = 0; i < (size_t)observation_count; ++i) {
            if (labels[i] == (int64_t)group) {
                const double difference = (double)input[3 + i] - group_means[group];
                ss_within += difference * difference;
            }
        }
    }
    if (!(ss_within > 0.0)) return INVALID_RESULT;

    const double df_between = (double)(group_count - 1);
    const double df_within = (double)(observation_count - group_count);
    const double ms_between = ss_between / df_between;
    const double ms_within = ss_within / df_within;
    const double f_statistic = ms_between / ms_within;
    const double beta_x = df_within / (df_within + df_between * f_statistic);
    const double p_value = regularized_beta(beta_x, df_within / 2.0, df_between / 2.0);
    const double outputs[8] = {df_between, df_within, ss_between, ss_within,
                               ms_between, ms_within, f_statistic, p_value};
    return outputs[statistic];
}
