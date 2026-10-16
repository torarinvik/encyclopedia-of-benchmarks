module gaussian_mixture_model;

const usz MAX_SAMPLES = 16;
const usz MAX_INPUT_LENGTH = 19;
const double PI = 3.14159265358979323846264338327950288;
extern fn double exp(double value);
extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double fabs(double value);

fn double gmm_pdf(double value, double mean, double variance) {
    double difference = value - mean;
    return exp(-(difference * difference) / (2.0 * variance)) / sqrt(2.0 * PI * variance);
}

fn long gaussian_mixture_model(long *values, usz length, char *output, usz capacity) @export("gaussian_mixture_model") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    long max_iterations = values[1];
    long tolerance_micro = values[2];
    if (count_value < 2 || count_value > 16 || max_iterations < 1 || max_iterations > 20
            || tolerance_micro < 1 || tolerance_micro > 1000 || length != 3 + (usz)count_value) return -1;
    usz count = (usz)count_value;
    double[MAX_SAMPLES] data;
    long previous_sample = -5001;
    for (usz i = 0; i < count; i++) {
        long sample = values[3 + i];
        if (sample < -5000 || sample > 5000 || sample < previous_sample) return -1;
        previous_sample = sample;
        data[i] = (double)sample / 1000.0;
    }
    usz required = count + 1;
    if (output == null || capacity < required) return -2;

    double data_mean = 0.0;
    for (usz i = 0; i < count; i++) data_mean += data[i];
    data_mean /= (double)count;
    double variance = 0.0;
    for (usz i = 0; i < count; i++) {
        double difference = data[i] - data_mean;
        variance += difference * difference;
    }
    variance = variance / (double)(count - 1) + 1e-6;
    double[2] weights = {0.5, 0.5};
    double[2] means = {data[0], data[count - 1]};
    double[2] variances = {variance, variance};
    // Store sample-major explicitly. C3's nested fixed-array indexing can
    // otherwise alias the second component's values on this ABI.
    double[MAX_SAMPLES * 2] responsibilities;
    double tolerance = (double)tolerance_micro / 1000000.0;
    double previous_likelihood = 0.0;
    bool has_previous_likelihood = false;
    usz iterations = 0;

    for (usz iteration = 0; iteration < (usz)max_iterations; iteration++) {
        double[2] component_counts = {0.0, 0.0};
        for (usz i = 0; i < count; i++) {
            double probability0 = weights[0] * gmm_pdf(data[i], means[0], variances[0]);
            double probability1 = weights[1] * gmm_pdf(data[i], means[1], variances[1]);
            double total = probability0 + probability1;
            if (total == 0.0) return -1;
            responsibilities[i * 2] = probability0 / total;
            responsibilities[i * 2 + 1] = probability1 / total;
            component_counts[0] += responsibilities[i * 2];
            component_counts[1] += responsibilities[i * 2 + 1];
        }
        if (component_counts[0] <= 0.0 || component_counts[1] <= 0.0) return -1;
        for (usz component = 0; component < 2; component++) {
            weights[component] = component_counts[component] / (double)count;
            double weighted_sum = 0.0;
            for (usz i = 0; i < count; i++) weighted_sum += responsibilities[i * 2 + component] * data[i];
            means[component] = weighted_sum / component_counts[component];
            double covariance = 0.0;
            for (usz i = 0; i < count; i++) {
                double difference = data[i] - means[component];
                covariance += responsibilities[i * 2 + component] * difference * difference;
            }
            variances[component] = covariance / component_counts[component] + 1e-6;
        }
        double likelihood = 0.0;
        for (usz i = 0; i < count; i++) {
            double density = weights[0] * gmm_pdf(data[i], means[0], variances[0])
                             + weights[1] * gmm_pdf(data[i], means[1], variances[1]);
            likelihood += log(density + 1e-12);
        }
        iterations = iteration + 1;
        if (has_previous_likelihood && fabs(likelihood - previous_likelihood) < tolerance) break;
        previous_likelihood = likelihood;
        has_previous_likelihood = true;
    }
    output[0] = (char)iterations;
    for (usz i = 0; i < count; i++) {
        double probability0 = weights[0] * gmm_pdf(data[i], means[0], variances[0]);
        double probability1 = weights[1] * gmm_pdf(data[i], means[1], variances[1]);
        output[i + 1] = (char)(probability0 >= probability1 ? 0 : 1);
    }
    return (long)required;
}
