module adwin;

const usz MAX_SAMPLES = 256;
const usz MAX_LEVELS = 16;
const usz MAX_BUCKETS = 5;
const usz BUCKET_CAPACITY = 6;
const int MIN_SUBWINDOW = 5;
const double INPUT_SCALE = 1000000000.0;

fn double adwin_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (usz iteration = 0; iteration < 80; iteration++) root = 0.5 * (root + value / root);
    return root;
}

fn double adwin_ln(double value) {
    int exponent = 0;
    while (value >= 2.0) { value *= 0.5; exponent++; }
    double ratio = (value - 1.0) / (value + 1.0);
    double square = ratio * ratio;
    double term = ratio;
    double sum = 0.0;
    for (int iteration = 0; iteration < 40; iteration++) {
        sum += term / (double)(2 * iteration + 1);
        term *= square;
    }
    return 2.0 * sum + (double)exponent * 0.693147180559945309417232121458176568;
}

fn long adwin(long* input, usz length, char* output, usz output_capacity)
    @export("adwin") {
    if (input == null || length < 3 || length > 258) return -1;
    long sample_count_value = input[0];
    long delta_value = input[1];
    if (sample_count_value < 1 || sample_count_value > 256 || length != 2 + (usz)sample_count_value ||
        delta_value < 1 || delta_value > 100000000) return -1;
    usz sample_count = (usz)sample_count_value;
    for (usz i = 0; i < sample_count; i++) {
        if (input[2 + i] < -1000000000L || input[2 + i] > 1000000000L) return -1;
    }
    if (output == null || output_capacity < 16 * sample_count) return -2;

    int[MAX_LEVELS] sizes;
    double[MAX_LEVELS * BUCKET_CAPACITY] totals;
    double[MAX_LEVELS * BUCKET_CAPACITY] variances;
    for (usz i = 0; i < MAX_LEVELS; i++) sizes[i] = 0;
    for (usz i = 0; i < MAX_LEVELS * BUCKET_CAPACITY; i++) { totals[i] = 0.0; variances[i] = 0.0; }
    long width = 0;
    double total = 0.0;
    double variance = 0.0;
    double delta = (double)delta_value / INPUT_SCALE;
    usz bucket_count = 0;

    for (usz sample = 0; sample < sample_count; sample++) {
        double value = (double)input[2 + sample] / INPUT_SCALE;
        width++;
        usz slot = (usz)sizes[0];
        totals[slot] = value;
        variances[slot] = 0.0;
        sizes[0]++;
        bucket_count++;
        if (width > 1) {
            double deviation = value - total / (double)(width - 1);
            variance += (double)(width - 1) * deviation * deviation / (double)width;
        }
        total += value;

        for (usz level = 0; level + 1 < MAX_LEVELS && sizes[level] > (int)MAX_BUCKETS; level++) {
            double size = (double)(1L << level);
            usz base = level * BUCKET_CAPACITY;
            double first_mean = totals[base] / size;
            double second_mean = totals[base + 1] / size;
            double difference = first_mean - second_mean;
            double merged_variance = variances[base] + variances[base + 1] +
                size * size * difference * difference / (size + size);
            usz next_slot = (level + 1) * BUCKET_CAPACITY + (usz)sizes[level + 1];
            totals[next_slot] = totals[base] + totals[base + 1];
            variances[next_slot] = merged_variance;
            sizes[level + 1]++;
            for (int i = 2; i < sizes[level]; i++) {
                totals[base + (usz)(i - 2)] = totals[base + (usz)i];
                variances[base + (usz)(i - 2)] = variances[base + (usz)i];
            }
            sizes[level] -= 2;
            bucket_count--;
        }

        int changed = 0;
        int searching = 1;
        while (searching != 0 && width >= 2 * MIN_SUBWINDOW) {
            searching = 0;
            int stop = 0;
            long old_width = 0;
            double old_total = 0.0;
            for (int level = (int)MAX_LEVELS - 1; level >= 0 && stop == 0; level--) {
                usz base = (usz)level * BUCKET_CAPACITY;
                for (int bucket = 0; bucket < sizes[level]; bucket++) {
                    if (level == 0 && bucket == sizes[level] - 1) { stop = 1; break; }
                    old_width += 1L << level;
                    old_total += totals[base + (usz)bucket];
                    long recent_width = width - old_width;
                    double recent_total = total - old_total;
                    if (recent_width < MIN_SUBWINDOW) { stop = 1; break; }
                    if (old_width >= MIN_SUBWINDOW) {
                        double harmonic = 1.0 / (double)(old_width - MIN_SUBWINDOW + 1) +
                            1.0 / (double)(recent_width - MIN_SUBWINDOW + 1);
                        double confidence = adwin_ln(2.0 * adwin_ln((double)width) / delta);
                        double window_variance = variance / (double)width;
                        double epsilon = adwin_sqrt(2.0 * harmonic * window_variance * confidence) +
                            2.0 / 3.0 * confidence * harmonic;
                        double difference = old_total / (double)old_width - recent_total / (double)recent_width;
                        if ((difference < 0.0 ? -difference : difference) > epsilon) {
                            changed = 1;
                            searching = 1;
                            int oldest_level = (int)MAX_LEVELS - 1;
                            while (oldest_level > 0 && sizes[oldest_level] == 0) oldest_level--;
                            long bucket_size = 1L << oldest_level;
                            usz oldest_base = (usz)oldest_level * BUCKET_CAPACITY;
                            double bucket_total = totals[oldest_base];
                            width -= bucket_size;
                            total -= bucket_total;
                            if (width > 0) {
                                double bucket_mean = bucket_total / (double)bucket_size;
                                double drop_difference = bucket_mean - total / (double)width;
                                variance -= variances[oldest_base] + (double)bucket_size * (double)width *
                                    drop_difference * drop_difference / (double)(bucket_size + width);
                            } else {
                                variance = 0.0;
                            }
                            if (variance < 0.0) variance = 0.0;
                            for (int i = 1; i < sizes[oldest_level]; i++) {
                                totals[oldest_base + (usz)(i - 1)] = totals[oldest_base + (usz)i];
                                variances[oldest_base + (usz)(i - 1)] = variances[oldest_base + (usz)i];
                            }
                            sizes[oldest_level]--;
                            bucket_count--;
                            stop = 1;
                            break;
                        }
                    }
                }
            }
        }
        long flag = (long)changed;
        ulong flag_bits = (ulong)flag;
        ulong width_bits = (ulong)width;
        for (usz byte = 0; byte < 8; byte++) {
            output[16 * sample + byte] = (char)((flag_bits >> (8 * byte)) & 255);
            output[16 * sample + 8 + byte] = (char)((width_bits >> (8 * byte)) & 255);
        }
    }
    return (long)(2 * sample_count);
}
