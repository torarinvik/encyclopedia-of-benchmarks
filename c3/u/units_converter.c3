module units_converter;

const long MAX_UNITS = 8;
const long MAX_CONVERSIONS = MAX_UNITS * MAX_UNITS;
const long MAX_VALUE_MICRO = 1000000000000;
const long MAX_SLOPE_PPM = 5000000;
const long MAX_INTERCEPT_MICRO = 1000000000000;
const double INVALID_RESULT = -1.0e300;

fn long find_root(long* parent, long node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn bool put_if_needed(long* present, double* slopes, double* intercepts,
                      long source, long target, double slope, double intercept) {
    if (source == target) return false;
    long slot = source * MAX_UNITS + target;
    if (present[slot] != 0) return false;
    present[slot] = 1;
    slopes[slot] = slope;
    intercepts[slot] = intercept;
    return true;
}

fn usz add_all(long* known_present, double* known_slopes, double* known_intercepts,
               long unit_count, long* result_present, double* result_slopes,
               double* result_intercepts) {
    long[MAX_CONVERSIONS] inverse_present = {};
    double[MAX_CONVERSIONS] inverse_slopes = {};
    double[MAX_CONVERSIONS] inverse_intercepts = {};
    usz inverse_count = 0;
    for (long source = 0; source < unit_count; source++) {
        for (long target = 0; target < unit_count; target++) {
            long slot = source * MAX_UNITS + target;
            if (known_present[slot] == 0) continue;
            if (put_if_needed(&inverse_present[0], &inverse_slopes[0], &inverse_intercepts[0],
                              source, target, known_slopes[slot], known_intercepts[slot])) inverse_count++;
            if (put_if_needed(&inverse_present[0], &inverse_slopes[0], &inverse_intercepts[0],
                              target, source, 1.0 / known_slopes[slot],
                              -known_intercepts[slot] / known_slopes[slot])) inverse_count++;
        }
    }

    usz result_count = 0;
    for (long first_source = 0; first_source < unit_count; first_source++) {
        for (long middle = 0; middle < unit_count; middle++) {
            long first_slot = first_source * MAX_UNITS + middle;
            if (inverse_present[first_slot] == 0) continue;
            if (put_if_needed(result_present, result_slopes, result_intercepts,
                              first_source, middle, inverse_slopes[first_slot], inverse_intercepts[first_slot])) result_count++;
            for (long target = 0; target < unit_count; target++) {
                long second_slot = middle * MAX_UNITS + target;
                if (inverse_present[second_slot] == 0) continue;
                if (put_if_needed(result_present, result_slopes, result_intercepts, first_source, target,
                                  inverse_slopes[second_slot] * inverse_slopes[first_slot],
                                  inverse_slopes[second_slot] * inverse_intercepts[first_slot] +
                                      inverse_intercepts[second_slot])) result_count++;
            }
        }
    }
    return result_count;
}

fn double units_converter_impl(long* values, usz length) {
    if (values == null || length < 4 || length > 35) return INVALID_RESULT;
    long source_value, target_value, value_micro, unit_count;
    long[MAX_CONVERSIONS] known_present = {};
    double[MAX_CONVERSIONS] known_slopes = {};
    double[MAX_CONVERSIONS] known_intercepts = {};
    usz known_count = 0;

    if (values[0] == 0) {
        if (length != 4) return INVALID_RESULT;
        source_value = values[1];
        target_value = values[2];
        value_micro = values[3];
        unit_count = 6;
        long[5] source_units = {0, 1, 3, 4, 5};
        long[5] target_units = {1, 2, 1, 1, 0};
        double[5] slopes = {1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0};
        double[5] intercepts = {-273.15, 32.0, 0.0, 100.0, 0.0};
        for (usz edge = 0; edge < 5; edge++) {
            long slot = source_units[edge] * MAX_UNITS + target_units[edge];
            known_present[slot] = 1;
            known_slopes[slot] = slopes[edge];
            known_intercepts[slot] = intercepts[edge];
            known_count++;
        }
    } else if (values[0] == 1) {
        if (length < 6) return INVALID_RESULT;
        long unit_count_value = values[1];
        long edge_count = values[2];
        source_value = values[3];
        target_value = values[4];
        value_micro = values[5];
        if (unit_count_value < 2 || unit_count_value > MAX_UNITS || edge_count < 0 ||
            edge_count > unit_count_value - 1 || length != (usz)(6 + 4 * edge_count)) return INVALID_RESULT;
        unit_count = unit_count_value;
        long[MAX_UNITS] parent;
        for (long unit = 0; unit < unit_count; unit++) parent[unit] = unit;
        for (long edge = 0; edge < edge_count; edge++) {
            usz offset = (usz)(6 + 4 * edge);
            long from = values[offset], to = values[offset + 1];
            long slope_ppm = values[offset + 2], intercept_micro = values[offset + 3];
            if (from < 0 || from >= unit_count_value || to < 0 || to >= unit_count_value || from == to ||
                slope_ppm == 0 || slope_ppm < -MAX_SLOPE_PPM || slope_ppm > MAX_SLOPE_PPM ||
                intercept_micro < -MAX_INTERCEPT_MICRO || intercept_micro > MAX_INTERCEPT_MICRO) return INVALID_RESULT;
            long root_from = find_root(&parent[0], from), root_to = find_root(&parent[0], to);
            if (root_from == root_to) return INVALID_RESULT;
            parent[root_from] = root_to;
            long slot = from * MAX_UNITS + to;
            known_present[slot] = 1;
            known_slopes[slot] = (double)slope_ppm / 1000000.0;
            known_intercepts[slot] = (double)intercept_micro / 1000000.0;
            known_count++;
        }
    } else {
        return INVALID_RESULT;
    }

    if (source_value < 0 || source_value >= unit_count || target_value < 0 || target_value >= unit_count ||
        source_value == target_value || value_micro < -MAX_VALUE_MICRO || value_micro > MAX_VALUE_MICRO) return INVALID_RESULT;

    bool stable = false;
    for (long iteration = 0; iteration <= MAX_UNITS; iteration++) {
        long[MAX_CONVERSIONS] next_present = {};
        double[MAX_CONVERSIONS] next_slopes = {};
        double[MAX_CONVERSIONS] next_intercepts = {};
        usz next_count = add_all(&known_present[0], &known_slopes[0], &known_intercepts[0], unit_count,
                                 &next_present[0], &next_slopes[0], &next_intercepts[0]);
        for (long slot = 0; slot < MAX_CONVERSIONS; slot++) {
            known_present[slot] = next_present[slot];
            known_slopes[slot] = next_slopes[slot];
            known_intercepts[slot] = next_intercepts[slot];
        }
        if (next_count == known_count) {
            stable = true;
            break;
        }
        known_count = next_count;
    }
    if (!stable) return INVALID_RESULT;

    long result_slot = source_value * MAX_UNITS + target_value;
    if (known_present[result_slot] == 0) return INVALID_RESULT;
    double value = (double)value_micro / 1000000.0;
    return known_slopes[result_slot] * value + known_intercepts[result_slot];
}

fn double units_converter(long* values, usz length) @export("units_converter") {
    return units_converter_impl(values, length);
}
