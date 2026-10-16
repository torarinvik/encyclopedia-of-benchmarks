const MAX_UNITS: usize = 8;
const MAX_CONVERSIONS: usize = MAX_UNITS * MAX_UNITS;
const MAX_VALUE_MICRO: i64 = 1_000_000_000_000;
const MAX_SLOPE_PPM: i64 = 5_000_000;
const MAX_INTERCEPT_MICRO: i64 = 1_000_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

fn find_root(parent: &mut [i64; MAX_UNITS], node: i64) -> i64 {
    let mut current = node as usize;
    while parent[current] != current as i64 {
        parent[current] = parent[parent[current] as usize];
        current = parent[current] as usize;
    }
    current as i64
}

fn put_if_needed(
    present: &mut [i64; MAX_CONVERSIONS],
    slopes: &mut [f64; MAX_CONVERSIONS],
    intercepts: &mut [f64; MAX_CONVERSIONS],
    count: &mut usize,
    source: usize,
    target: usize,
    slope: f64,
    intercept: f64,
) {
    if source == target { return; }
    let slot = source * MAX_UNITS + target;
    if present[slot] != 0 { return; }
    present[slot] = 1;
    slopes[slot] = slope;
    intercepts[slot] = intercept;
    *count += 1;
}

fn add_all(
    known_present: &[i64; MAX_CONVERSIONS],
    known_slopes: &[f64; MAX_CONVERSIONS],
    known_intercepts: &[f64; MAX_CONVERSIONS],
    unit_count: usize,
    result_present: &mut [i64; MAX_CONVERSIONS],
    result_slopes: &mut [f64; MAX_CONVERSIONS],
    result_intercepts: &mut [f64; MAX_CONVERSIONS],
) -> usize {
    let mut inverse_present = [0i64; MAX_CONVERSIONS];
    let mut inverse_slopes = [0.0f64; MAX_CONVERSIONS];
    let mut inverse_intercepts = [0.0f64; MAX_CONVERSIONS];
    let mut inverse_count = 0;
    for source in 0..unit_count {
        for target in 0..unit_count {
            let slot = source * MAX_UNITS + target;
            if known_present[slot] == 0 { continue; }
            put_if_needed(&mut inverse_present, &mut inverse_slopes, &mut inverse_intercepts,
                          &mut inverse_count, source, target, known_slopes[slot], known_intercepts[slot]);
            put_if_needed(&mut inverse_present, &mut inverse_slopes, &mut inverse_intercepts,
                          &mut inverse_count, target, source, 1.0 / known_slopes[slot],
                          -known_intercepts[slot] / known_slopes[slot]);
        }
    }

    let mut result_count = 0;
    for first_source in 0..unit_count {
        for middle in 0..unit_count {
            let first_slot = first_source * MAX_UNITS + middle;
            if inverse_present[first_slot] == 0 { continue; }
            put_if_needed(result_present, result_slopes, result_intercepts, &mut result_count,
                          first_source, middle, inverse_slopes[first_slot], inverse_intercepts[first_slot]);
            for target in 0..unit_count {
                let second_slot = middle * MAX_UNITS + target;
                if inverse_present[second_slot] == 0 { continue; }
                put_if_needed(result_present, result_slopes, result_intercepts, &mut result_count,
                              first_source, target,
                              inverse_slopes[second_slot] * inverse_slopes[first_slot],
                              inverse_slopes[second_slot] * inverse_intercepts[first_slot] +
                                  inverse_intercepts[second_slot]);
            }
        }
    }
    result_count
}

#[no_mangle]
pub unsafe extern "C" fn units_converter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(4..=35).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let source_value: i64;
    let target_value: i64;
    let value_micro: i64;
    let unit_count: usize;
    let mut known_present = [0i64; MAX_CONVERSIONS];
    let mut known_slopes = [0.0f64; MAX_CONVERSIONS];
    let mut known_intercepts = [0.0f64; MAX_CONVERSIONS];
    let mut known_count = 0;

    if values[0] == 0 {
        if length != 4 { return INVALID_RESULT; }
        source_value = values[1];
        target_value = values[2];
        value_micro = values[3];
        unit_count = 6;
        let edges = [
            (0usize, 1usize, 1.0, -273.15),
            (1, 2, 9.0 / 5.0, 32.0),
            (3, 1, 5.0 / 4.0, 0.0),
            (4, 1, -2.0 / 3.0, 100.0),
            (5, 0, 5.0 / 9.0, 0.0),
        ];
        for (source, target, slope, intercept) in edges {
            let slot = source * MAX_UNITS + target;
            known_present[slot] = 1;
            known_slopes[slot] = slope;
            known_intercepts[slot] = intercept;
            known_count += 1;
        }
    } else if values[0] == 1 {
        if length < 6 { return INVALID_RESULT; }
        let unit_count_value = values[1];
        let edge_count = values[2];
        if unit_count_value < 2 || unit_count_value > MAX_UNITS as i64 || edge_count < 0 ||
            edge_count > unit_count_value - 1 || length != (6 + 4 * edge_count) as usize {
            return INVALID_RESULT;
        }
        source_value = values[3];
        target_value = values[4];
        value_micro = values[5];
        unit_count = unit_count_value as usize;
        let mut parent = [0i64; MAX_UNITS];
        for unit in 0..unit_count { parent[unit] = unit as i64; }
        for edge in 0..edge_count as usize {
            let offset = 6 + 4 * edge;
            let from = values[offset];
            let to = values[offset + 1];
            let slope_ppm = values[offset + 2];
            let intercept_micro = values[offset + 3];
            if from < 0 || from >= unit_count_value || to < 0 || to >= unit_count_value || from == to ||
                slope_ppm == 0 || slope_ppm < -MAX_SLOPE_PPM || slope_ppm > MAX_SLOPE_PPM ||
                intercept_micro < -MAX_INTERCEPT_MICRO || intercept_micro > MAX_INTERCEPT_MICRO {
                return INVALID_RESULT;
            }
            let root_from = find_root(&mut parent, from);
            let root_to = find_root(&mut parent, to);
            if root_from == root_to { return INVALID_RESULT; }
            parent[root_from as usize] = root_to;
            let slot = from as usize * MAX_UNITS + to as usize;
            known_present[slot] = 1;
            known_slopes[slot] = slope_ppm as f64 / 1_000_000.0;
            known_intercepts[slot] = intercept_micro as f64 / 1_000_000.0;
            known_count += 1;
        }
    } else {
        return INVALID_RESULT;
    }

    if source_value < 0 || source_value >= unit_count as i64 || target_value < 0 ||
        target_value >= unit_count as i64 || source_value == target_value ||
        value_micro < -MAX_VALUE_MICRO || value_micro > MAX_VALUE_MICRO {
        return INVALID_RESULT;
    }

    let mut stable = false;
    for _ in 0..=MAX_UNITS {
        let mut next_present = [0i64; MAX_CONVERSIONS];
        let mut next_slopes = [0.0f64; MAX_CONVERSIONS];
        let mut next_intercepts = [0.0f64; MAX_CONVERSIONS];
        let next_count = add_all(&known_present, &known_slopes, &known_intercepts, unit_count,
                                 &mut next_present, &mut next_slopes, &mut next_intercepts);
        known_present = next_present;
        known_slopes = next_slopes;
        known_intercepts = next_intercepts;
        if next_count == known_count {
            stable = true;
            break;
        }
        known_count = next_count;
    }
    if !stable { return INVALID_RESULT; }

    let result_slot = source_value as usize * MAX_UNITS + target_value as usize;
    if known_present[result_slot] == 0 { return INVALID_RESULT; }
    let value = value_micro as f64 / 1_000_000.0;
    known_slopes[result_slot] * value + known_intercepts[result_slot]
}
