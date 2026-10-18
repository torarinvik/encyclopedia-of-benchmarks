module tdigest;

const usz MAX_SAMPLES = 32;
const usz MAX_QUERIES = 4;
const usz MAX_INPUT_LENGTH = 45;
const usz MAX_VALID_INPUT_LENGTH = 44;
const usz MAX_CENTROIDS = 44;
const usz MAX_OUTPUT_LENGTH = 10;
const double TWO_PI = 6.283185307179586476925286766559;

extern fn double sqrt(double value);
extern fn double asin(double value);
extern fn double sin(double value);
extern fn double trunc(double value);

fn bool finite_value(double value) { return value == value && value < 1e300 && value > -1e300; }

fn bool integer_in_range(double value, int low, int high) {
    return finite_value(value) && value >= (double)low && value <= (double)high && value == trunc(value);
}

fn double interpolate(double x0, double y0, double x1, double y1, double x) {
    if (x1 <= x0) return y1;
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0);
}

fn double quantile_limit(double compression, double q) {
    if (q < 0.0) q = 0.0;
    if (q > 1.0) q = 1.0;
    double k = compression / TWO_PI * asin(2.0 * q - 1.0) + 1.0;
    double angle = k * TWO_PI / compression;
    if (angle >= 1.57079632679489661923) return 1.0;
    if (angle <= -1.57079632679489661923) return 0.0;
    return (sin(angle) + 1.0) / 2.0;
}

fn double quantile(double q, double* means, double* weights, usz centroid_count,
                   double total_weight, double minimum, double maximum) {
    if (centroid_count == 1) return means[0];
    double index = q * total_weight;
    if (index <= 0.0) return minimum;
    if (index >= total_weight) return maximum;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (usz i = 0; i < centroid_count; i++) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (index < current_index)
            return interpolate(previous_index, previous_value, current_index, means[i], index);
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_index, previous_value, total_weight, maximum, index);
}

fn double cdf(double value, double* means, double* weights, usz centroid_count,
             double total_weight, double minimum, double maximum) {
    if (value < minimum) return 0.0;
    if (value > maximum) return 1.0;
    if (maximum <= minimum) return 0.5;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (usz i = 0; i < centroid_count; i++) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (value < means[i])
            return interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight;
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight;
}

fn long tdigest(double* input, usz input_length, double* output, usz output_capacity)
    @export("tdigest") {
    if (input == null || input_length < 7 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;
    if (!integer_in_range(input[0], 10, 20) || !integer_in_range(input[1], 1, (int)MAX_SAMPLES)) return -1L;
    usz sample_count = (usz)(long)input[1];
    usz q_count_index = 2 + sample_count;
    if (q_count_index >= input_length || !integer_in_range(input[q_count_index], 1, (int)MAX_QUERIES)) return -1L;
    usz q_count = (usz)(long)input[q_count_index];
    usz q_start = q_count_index + 1;
    usz cdf_count_index = q_start + q_count;
    if (cdf_count_index >= input_length || !integer_in_range(input[cdf_count_index], 1, (int)MAX_QUERIES)) return -1L;
    usz cdf_count = (usz)(long)input[cdf_count_index];
    usz cdf_start = cdf_count_index + 1;
    if (input_length != cdf_start + cdf_count || input_length > MAX_VALID_INPUT_LENGTH) return -1L;

    double[MAX_SAMPLES] sorted = zeroed;
    double[MAX_QUERIES] probabilities = zeroed;
    double[MAX_QUERIES] cdf_values = zeroed;
    for (usz i = 0; i < sample_count; i++) {
        double value = input[2 + i];
        if (!integer_in_range(value, -8, 8)) return -1L;
        sorted[i] = value;
    }
    for (usz i = 0; i < q_count; i++) {
        double q = input[q_start + i];
        if (q < 0.0 || q > 1.0 || q * 4.0 != trunc(q * 4.0)) return -1L;
        probabilities[i] = q;
    }
    for (usz i = 0; i < cdf_count; i++) {
        double value = input[cdf_start + i];
        if (!integer_in_range(value, -8, 8)) return -1L;
        cdf_values[i] = value;
    }
    for (usz i = 1; i < sample_count; i++) {
        double value = sorted[i];
        usz j = i;
        while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; j--; }
        sorted[j] = value;
    }

    double compression = input[0];
    double total_weight = (double)sample_count;
    usz centroid_capacity = 2 * ((usz)(long)compression + 2);
    double[MAX_CENTROIDS] means = zeroed;
    double[MAX_CENTROIDS] weights = zeroed;
    usz last = 0;
    means[0] = sorted[0];
    weights[0] = 1.0;
    double closed_weight = 0.0;
    double weight_limit = total_weight * quantile_limit(compression, 0.0);
    for (usz i = 1; i < sample_count; i++) {
        double projected = weights[last] + 1.0;
        bool room_left = closed_weight + projected <= weight_limit;
        if (room_left || last == centroid_capacity - 1) {
            weights[last] = projected;
            means[last] += (sorted[i] - means[last]) / projected;
        } else {
            closed_weight += weights[last];
            weight_limit = total_weight * quantile_limit(compression, closed_weight / total_weight);
            last++;
            means[last] = sorted[i];
            weights[last] = 1.0;
        }
    }
    usz centroid_count = last + 1;
    double minimum = sorted[0];
    double maximum = sorted[sample_count - 1];
    double[MAX_OUTPUT_LENGTH] staged = zeroed;
    staged[0] = (double)q_count;
    for (usz i = 0; i < q_count; i++)
        staged[1 + i] = quantile(probabilities[i], &means[0], &weights[0], centroid_count, total_weight, minimum, maximum);
    staged[1 + q_count] = (double)cdf_count;
    for (usz i = 0; i < cdf_count; i++)
        staged[2 + q_count + i] = cdf(cdf_values[i], &means[0], &weights[0], centroid_count, total_weight, minimum, maximum);
    usz result_length = q_count + cdf_count + 2;
    if (output == null || output_capacity < result_length) return -2L;
    for (usz i = 0; i < result_length; i++) output[i] = staged[i];
    return (long)result_length;
}
