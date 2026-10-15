module anova_oneway;

extern fn double log(double value);
extern fn double exp(double value);

const usz MAX_OBSERVATIONS = 128;
const usz MAX_GROUPS = 8;
const double INVALID_RESULT = -1.0e300;

fn double safe_denominator(double value) {
    double minimum = 1.0e-300;
    double magnitude = value;
    if (magnitude < 0.0) magnitude = -magnitude;
    if (magnitude >= minimum) return value;
    if (value < 0.0) return -minimum;
    return minimum;
}

fn double log_gamma_lanczos(double value) {
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
    double t = z + 7.5;
    return 0.91893853320467274178 + (z + 0.5) * log(t) - t + log(sum);
}

fn double beta_fraction(double a, double b, double x) {
    double qab = a + b;
    double qap = a + 1.0;
    double qam = a - 1.0;
    double c = 1.0;
    double d = safe_denominator(1.0 - qab * x / qap);
    d = 1.0 / d;
    double result = d;
    for (int m = 1; m <= 200; m++) {
        double md = (double)m;
        double m2 = 2.0 * md;
        double coefficient = md * (b - md) * x / ((qam + m2) * (a + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        result *= d * c;
        coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        double change = d * c;
        result *= change;
        double difference = change - 1.0;
        if (difference < 0.0) difference = -difference;
        if (difference <= 3.0e-14) break;
    }
    return result;
}

fn double regularized_beta(double x, double a, double b) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    double front = exp(a * log(x) + b * log(1.0 - x) +
                       log_gamma_lanczos(a + b) - log_gamma_lanczos(a) - log_gamma_lanczos(b));
    if (x < (a + 1.0) / (a + b + 2.0)) return front * beta_fraction(a, b, x) / a;
    return 1.0 - front * beta_fraction(b, a, 1.0 - x) / b;
}

fn double anova_oneway(long* input, usz length) @export("anova_oneway") {
    if (input == null || length < 3) return INVALID_RESULT;
    long statistic = input[0];
    long observation_count = input[1];
    long group_count = input[2];
    if (statistic < 0 || statistic > 7 || observation_count <= group_count ||
        observation_count > (long)MAX_OBSERVATIONS || group_count < 2 || group_count > (long)MAX_GROUPS ||
        length != 3 + 2 * (usz)observation_count) return INVALID_RESULT;

    usz observations = (usz)observation_count;
    usz groups = (usz)group_count;
    double[MAX_GROUPS] group_sums;
    double[MAX_GROUPS] group_means;
    long[MAX_GROUPS] group_sizes;
    long[MAX_OBSERVATIONS] labels;
    for (usz group = 0; group < MAX_GROUPS; group++) {
        group_sums[group] = 0.0;
        group_means[group] = 0.0;
        group_sizes[group] = 0;
    }
    double total = 0.0;
    for (usz i = 0; i < observations; i++) {
        long value = input[3 + i];
        long group = input[3 + observations + i];
        if (value < -1000000 || value > 1000000 || group < 0 || group >= group_count) return INVALID_RESULT;
        labels[i] = group;
        usz group_index = (usz)group;
        group_sums[group_index] += (double)value;
        group_sizes[group_index]++;
        total += (double)value;
    }
    for (usz group = 0; group < groups; group++) {
        if (group_sizes[group] == 0) return INVALID_RESULT;
        group_means[group] = group_sums[group] / (double)group_sizes[group];
    }
    double grand_mean = total / (double)observation_count;
    double ss_between = 0.0;
    for (usz group = 0; group < groups; group++) {
        double difference = group_means[group] - grand_mean;
        ss_between += (double)group_sizes[group] * difference * difference;
    }
    double ss_within = 0.0;
    for (usz group = 0; group < groups; group++) {
        for (usz i = 0; i < observations; i++) {
            if (labels[i] == (long)group) {
                double difference = (double)input[3 + i] - group_means[group];
                ss_within += difference * difference;
            }
        }
    }
    if (ss_within <= 0.0) return INVALID_RESULT;

    double df_between = (double)(group_count - 1);
    double df_within = (double)(observation_count - group_count);
    double ms_between = ss_between / df_between;
    double ms_within = ss_within / df_within;
    double f_statistic = ms_between / ms_within;
    double beta_x = df_within / (df_within + df_between * f_statistic);
    double p_value = regularized_beta(beta_x, df_within / 2.0, df_between / 2.0);
    double[8] outputs;
    outputs[0] = df_between;
    outputs[1] = df_within;
    outputs[2] = ss_between;
    outputs[3] = ss_within;
    outputs[4] = ms_between;
    outputs[5] = ms_within;
    outputs[6] = f_statistic;
    outputs[7] = p_value;
    return outputs[(usz)statistic];
}
