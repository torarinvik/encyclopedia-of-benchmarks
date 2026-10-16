/* Bounded inverse-and-composition closure for affine unit conversions. */
#include <stddef.h>
#include <stdint.h>

#define MAX_UNITS 8
#define MAX_CONVERSIONS (MAX_UNITS * MAX_UNITS)
#define MAX_INPUT_LENGTH 35
#define MAX_VALUE_MICRO INT64_C(1000000000000)
#define MAX_SLOPE_PPM INT64_C(5000000)
#define MAX_INTERCEPT_MICRO INT64_C(1000000000000)
#define INVALID_RESULT (-1.0e300)

static int find_root(int64_t parent[MAX_UNITS], int64_t node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return (int)node;
}

static void put_if_needed(int present[MAX_CONVERSIONS], double slopes[MAX_CONVERSIONS],
                          double intercepts[MAX_CONVERSIONS], size_t *count,
                          int source, int target, double slope, double intercept) {
    if (source == target) return;
    const int slot = source * MAX_UNITS + target;
    if (present[slot]) return;
    present[slot] = 1;
    slopes[slot] = slope;
    intercepts[slot] = intercept;
    ++*count;
}

static size_t add_all(const int known_present[MAX_CONVERSIONS],
                      const double known_slopes[MAX_CONVERSIONS],
                      const double known_intercepts[MAX_CONVERSIONS], int unit_count,
                      int result_present[MAX_CONVERSIONS],
                      double result_slopes[MAX_CONVERSIONS],
                      double result_intercepts[MAX_CONVERSIONS]) {
    int inverse_present[MAX_CONVERSIONS] = {0};
    double inverse_slopes[MAX_CONVERSIONS] = {0.0};
    double inverse_intercepts[MAX_CONVERSIONS] = {0.0};
    size_t inverse_count = 0;
    for (int source = 0; source < unit_count; ++source) {
        for (int target = 0; target < unit_count; ++target) {
            const int slot = source * MAX_UNITS + target;
            if (!known_present[slot]) continue;
            put_if_needed(inverse_present, inverse_slopes, inverse_intercepts, &inverse_count,
                          source, target, known_slopes[slot], known_intercepts[slot]);
            put_if_needed(inverse_present, inverse_slopes, inverse_intercepts, &inverse_count,
                          target, source, 1.0 / known_slopes[slot],
                          -known_intercepts[slot] / known_slopes[slot]);
        }
    }

    size_t result_count = 0;
    for (int first_source = 0; first_source < unit_count; ++first_source) {
        for (int middle = 0; middle < unit_count; ++middle) {
            const int first_slot = first_source * MAX_UNITS + middle;
            if (!inverse_present[first_slot]) continue;
            put_if_needed(result_present, result_slopes, result_intercepts, &result_count,
                          first_source, middle, inverse_slopes[first_slot], inverse_intercepts[first_slot]);
            for (int target = 0; target < unit_count; ++target) {
                const int second_slot = middle * MAX_UNITS + target;
                if (!inverse_present[second_slot]) continue;
                put_if_needed(result_present, result_slopes, result_intercepts, &result_count,
                              first_source, target,
                              inverse_slopes[second_slot] * inverse_slopes[first_slot],
                              inverse_slopes[second_slot] * inverse_intercepts[first_slot] +
                                  inverse_intercepts[second_slot]);
            }
        }
    }
    return result_count;
}

double units_converter(const int64_t *values, size_t length) {
    if (values == NULL || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int64_t source_value, target_value, value_micro, unit_count_value;
    int known_present[MAX_CONVERSIONS] = {0};
    double known_slopes[MAX_CONVERSIONS] = {0.0};
    double known_intercepts[MAX_CONVERSIONS] = {0.0};
    size_t known_count = 0;
    int unit_count;

    if (values[0] == 0) {
        if (length != 4) return INVALID_RESULT;
        source_value = values[1];
        target_value = values[2];
        value_micro = values[3];
        unit_count = 6;
        const int source_units[] = {0, 1, 3, 4, 5};
        const int target_units[] = {1, 2, 1, 1, 0};
        const double slopes[] = {1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0};
        const double intercepts[] = {-273.15, 32.0, 0.0, 100.0, 0.0};
        for (size_t edge = 0; edge < 5; ++edge) {
            const int slot = source_units[edge] * MAX_UNITS + target_units[edge];
            known_present[slot] = 1;
            known_slopes[slot] = slopes[edge];
            known_intercepts[slot] = intercepts[edge];
            ++known_count;
        }
    } else if (values[0] == 1) {
        if (length < 6) return INVALID_RESULT;
        unit_count_value = values[1];
        const int64_t edge_count = values[2];
        source_value = values[3];
        target_value = values[4];
        value_micro = values[5];
        if (unit_count_value < 2 || unit_count_value > MAX_UNITS || edge_count < 0 ||
            edge_count > unit_count_value - 1 || length != (size_t)(6 + 4 * edge_count)) return INVALID_RESULT;
        unit_count = (int)unit_count_value;
        int64_t parent[MAX_UNITS];
        for (int unit = 0; unit < unit_count; ++unit) parent[unit] = unit;
        for (int64_t edge = 0; edge < edge_count; ++edge) {
            const size_t offset = (size_t)(6 + 4 * edge);
            const int64_t from = values[offset], to = values[offset + 1];
            const int64_t slope_ppm = values[offset + 2], intercept_micro = values[offset + 3];
            if (from < 0 || from >= unit_count_value || to < 0 || to >= unit_count_value || from == to ||
                slope_ppm == 0 || slope_ppm < -MAX_SLOPE_PPM || slope_ppm > MAX_SLOPE_PPM ||
                intercept_micro < -MAX_INTERCEPT_MICRO || intercept_micro > MAX_INTERCEPT_MICRO) return INVALID_RESULT;
            const int root_from = find_root(parent, from), root_to = find_root(parent, to);
            if (root_from == root_to) return INVALID_RESULT;
            parent[root_from] = root_to;
            const int slot = (int)from * MAX_UNITS + (int)to;
            known_present[slot] = 1;
            known_slopes[slot] = (double)slope_ppm / 1000000.0;
            known_intercepts[slot] = (double)intercept_micro / 1000000.0;
            ++known_count;
        }
    } else {
        return INVALID_RESULT;
    }

    if (source_value < 0 || source_value >= unit_count || target_value < 0 || target_value >= unit_count ||
        source_value == target_value || value_micro < -MAX_VALUE_MICRO || value_micro > MAX_VALUE_MICRO) return INVALID_RESULT;

    int stable = 0;
    for (int iteration = 0; iteration <= MAX_UNITS; ++iteration) {
        int next_present[MAX_CONVERSIONS] = {0};
        double next_slopes[MAX_CONVERSIONS] = {0.0};
        double next_intercepts[MAX_CONVERSIONS] = {0.0};
        const size_t next_count = add_all(known_present, known_slopes, known_intercepts, unit_count,
                                          next_present, next_slopes, next_intercepts);
        for (int slot = 0; slot < MAX_CONVERSIONS; ++slot) {
            known_present[slot] = next_present[slot];
            known_slopes[slot] = next_slopes[slot];
            known_intercepts[slot] = next_intercepts[slot];
        }
        if (next_count == known_count) {
            stable = 1;
            break;
        }
        known_count = next_count;
    }
    if (!stable) return INVALID_RESULT;

    const int result_slot = (int)source_value * MAX_UNITS + (int)target_value;
    if (!known_present[result_slot]) return INVALID_RESULT;
    const double value = (double)value_micro / 1000000.0;
    return known_slopes[result_slot] * value + known_intercepts[result_slot];
}
