#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 256
#define MAX_LEVELS 16
#define MAX_BUCKETS 5
#define BUCKET_CAPACITY (MAX_BUCKETS + 1)
#define MIN_SUBWINDOW 5
#define INPUT_SCALE 1000000000.0

typedef struct {
    int sizes[MAX_LEVELS];
    double totals[MAX_LEVELS][BUCKET_CAPACITY];
    double variances[MAX_LEVELS][BUCKET_CAPACITY];
    int64_t width;
    double total;
    double variance;
    int bucket_count;
    double delta;
} Adwin;

static double adwin_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}

static double adwin_ln(double value) {
    int exponent = 0;
    while (value >= 2.0) { value *= 0.5; ++exponent; }
    const double ratio = (value - 1.0) / (value + 1.0);
    const double square = ratio * ratio;
    double term = ratio;
    double sum = 0.0;
    for (int iteration = 0; iteration < 40; ++iteration) {
        sum += term / (double)(2 * iteration + 1);
        term *= square;
    }
    return 2.0 * sum + (double)exponent * 0.693147180559945309417232121458176568;
}

static void adwin_add_bucket(Adwin *state, int level, double total, double variance) {
    const int slot = state->sizes[level]++;
    state->totals[level][slot] = total;
    state->variances[level][slot] = variance;
}

static void adwin_remove_oldest(Adwin *state, int level, int count) {
    const int old_size = state->sizes[level];
    for (int i = count; i < old_size; ++i) {
        state->totals[level][i - count] = state->totals[level][i];
        state->variances[level][i - count] = state->variances[level][i];
    }
    state->sizes[level] -= count;
}

static void adwin_compress(Adwin *state) {
    for (int level = 0; level + 1 < MAX_LEVELS && state->sizes[level] > MAX_BUCKETS; ++level) {
        const double size = (double)(1 << level);
        const double first_mean = state->totals[level][0] / size;
        const double second_mean = state->totals[level][1] / size;
        const double difference = first_mean - second_mean;
        const double merged_variance = state->variances[level][0] + state->variances[level][1] +
            size * size * difference * difference / (size + size);
        adwin_add_bucket(state, level + 1, state->totals[level][0] + state->totals[level][1], merged_variance);
        adwin_remove_oldest(state, level, 2);
        --state->bucket_count;
    }
}

static void adwin_insert(Adwin *state, double value) {
    ++state->width;
    adwin_add_bucket(state, 0, value, 0.0);
    ++state->bucket_count;
    if (state->width > 1) {
        const double deviation = value - state->total / (double)(state->width - 1);
        state->variance += (double)(state->width - 1) * deviation * deviation / (double)state->width;
    }
    state->total += value;
    adwin_compress(state);
}

static int adwin_significant(const Adwin *state, int64_t old_width, int64_t recent_width, double difference) {
    const double harmonic = 1.0 / (double)(old_width - MIN_SUBWINDOW + 1) +
        1.0 / (double)(recent_width - MIN_SUBWINDOW + 1);
    const double confidence = adwin_ln(2.0 * adwin_ln((double)state->width) / state->delta);
    const double window_variance = state->variance / (double)state->width;
    const double epsilon = adwin_sqrt(2.0 * harmonic * window_variance * confidence) +
        2.0 / 3.0 * confidence * harmonic;
    return difference < 0.0 ? -difference > epsilon : difference > epsilon;
}

static void adwin_drop_oldest(Adwin *state) {
    int level = MAX_LEVELS - 1;
    while (level > 0 && state->sizes[level] == 0) --level;
    const int64_t size = (int64_t)(1 << level);
    const double bucket_total = state->totals[level][0];
    state->width -= size;
    state->total -= bucket_total;
    if (state->width > 0) {
        const double bucket_mean = bucket_total / (double)size;
        const double difference = bucket_mean - state->total / (double)state->width;
        state->variance -= state->variances[level][0] + (double)size * (double)state->width *
            difference * difference / (double)(size + state->width);
    } else {
        state->variance = 0.0;
    }
    if (state->variance < 0.0) state->variance = 0.0;
    adwin_remove_oldest(state, level, 1);
    --state->bucket_count;
}

static int adwin_detect_change(Adwin *state) {
    int changed = 0;
    int searching = 1;
    while (searching && state->width >= 2 * MIN_SUBWINDOW) {
        searching = 0;
        int stop = 0;
        int64_t old_width = 0;
        double old_total = 0.0;
        for (int level = MAX_LEVELS - 1; level >= 0 && !stop; --level) {
            for (int bucket = 0; bucket < state->sizes[level]; ++bucket) {
                if (level == 0 && bucket == state->sizes[level] - 1) { stop = 1; break; }
                old_width += (int64_t)(1 << level);
                old_total += state->totals[level][bucket];
                const int64_t recent_width = state->width - old_width;
                const double recent_total = state->total - old_total;
                if (recent_width < MIN_SUBWINDOW) { stop = 1; break; }
                if (old_width >= MIN_SUBWINDOW &&
                    adwin_significant(state, old_width, recent_width,
                                      old_total / (double)old_width - recent_total / (double)recent_width)) {
                    changed = 1;
                    searching = 1;
                    adwin_drop_oldest(state);
                    stop = 1;
                    break;
                }
            }
        }
    }
    return changed;
}

static void adwin_write_i64(uint8_t *output, size_t word_index, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[8 * word_index + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t adwin(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 2 + MAX_SAMPLES) return -1;
    const int64_t sample_count_value = input[0], delta_value = input[1];
    if (sample_count_value < 1 || sample_count_value > MAX_SAMPLES || length != 2 + (size_t)sample_count_value ||
        delta_value < 1 || delta_value > 100000000) return -1;
    const size_t sample_count = (size_t)sample_count_value;
    for (size_t i = 0; i < sample_count; ++i)
        if (input[2 + i] < -1000000000LL || input[2 + i] > 1000000000LL) return -1;
    if (output == NULL || output_capacity < 16 * sample_count) return -2;

    Adwin state = {0};
    state.delta = (double)delta_value / INPUT_SCALE;
    for (size_t i = 0; i < sample_count; ++i) {
        adwin_insert(&state, (double)input[2 + i] / INPUT_SCALE);
        const int changed = adwin_detect_change(&state);
        adwin_write_i64(output, 2 * i, changed);
        adwin_write_i64(output, 2 * i + 1, state.width);
    }
    return (int64_t)(2 * sample_count);
}
