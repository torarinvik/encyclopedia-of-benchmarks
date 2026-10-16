const MAX_UNITS: usize = 8;
const MAX_CONVERSIONS: usize = MAX_UNITS * MAX_UNITS;
const MAX_VALUE_MICRO: i64 = 1_000_000_000_000;
const MAX_SLOPE_PPM: i64 = 5_000_000;
const MAX_INTERCEPT_MICRO: i64 = 1_000_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

fn findRoot(parent: *[MAX_UNITS]i64, node: i64) i64 {
    var current: usize = @intCast(node);
    while (parent[current] != @as(i64, @intCast(current))) {
        parent[current] = parent[@intCast(parent[current])];
        current = @intCast(parent[current]);
    }
    return @intCast(current);
}

fn putIfNeeded(
    present: *[MAX_CONVERSIONS]i64,
    slopes: *[MAX_CONVERSIONS]f64,
    intercepts: *[MAX_CONVERSIONS]f64,
    count: *usize,
    source: usize,
    target: usize,
    slope: f64,
    intercept: f64,
) void {
    if (source == target) return;
    const slot = source * MAX_UNITS + target;
    if (present[slot] != 0) return;
    present[slot] = 1;
    slopes[slot] = slope;
    intercepts[slot] = intercept;
    count.* += 1;
}

fn addAll(
    known_present: *const [MAX_CONVERSIONS]i64,
    known_slopes: *const [MAX_CONVERSIONS]f64,
    known_intercepts: *const [MAX_CONVERSIONS]f64,
    unit_count: usize,
    result_present: *[MAX_CONVERSIONS]i64,
    result_slopes: *[MAX_CONVERSIONS]f64,
    result_intercepts: *[MAX_CONVERSIONS]f64,
) usize {
    var inverse_present: [MAX_CONVERSIONS]i64 = @splat(0);
    var inverse_slopes: [MAX_CONVERSIONS]f64 = @splat(0.0);
    var inverse_intercepts: [MAX_CONVERSIONS]f64 = @splat(0.0);
    var inverse_count: usize = 0;
    for (0..unit_count) |source| {
        for (0..unit_count) |target| {
            const slot = source * MAX_UNITS + target;
            if (known_present[slot] == 0) continue;
            putIfNeeded(&inverse_present, &inverse_slopes, &inverse_intercepts, &inverse_count,
                source, target, known_slopes[slot], known_intercepts[slot]);
            putIfNeeded(&inverse_present, &inverse_slopes, &inverse_intercepts, &inverse_count,
                target, source, 1.0 / known_slopes[slot], -known_intercepts[slot] / known_slopes[slot]);
        }
    }

    var result_count: usize = 0;
    for (0..unit_count) |first_source| {
        for (0..unit_count) |middle| {
            const first_slot = first_source * MAX_UNITS + middle;
            if (inverse_present[first_slot] == 0) continue;
            putIfNeeded(result_present, result_slopes, result_intercepts, &result_count,
                first_source, middle, inverse_slopes[first_slot], inverse_intercepts[first_slot]);
            for (0..unit_count) |target| {
                const second_slot = middle * MAX_UNITS + target;
                if (inverse_present[second_slot] == 0) continue;
                putIfNeeded(result_present, result_slopes, result_intercepts, &result_count,
                    first_source, target,
                    inverse_slopes[second_slot] * inverse_slopes[first_slot],
                    inverse_slopes[second_slot] * inverse_intercepts[first_slot] + inverse_intercepts[second_slot]);
            }
        }
    }
    return result_count;
}

export fn units_converter(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 4 or length > 35) return INVALID_RESULT;
    var source_value: i64 = 0;
    var target_value: i64 = 0;
    var value_micro: i64 = 0;
    var unit_count: usize = 0;
    var known_present: [MAX_CONVERSIONS]i64 = @splat(0);
    var known_slopes: [MAX_CONVERSIONS]f64 = @splat(0.0);
    var known_intercepts: [MAX_CONVERSIONS]f64 = @splat(0.0);
    var known_count: usize = 0;

    if (values[0] == 0) {
        if (length != 4) return INVALID_RESULT;
        source_value = values[1];
        target_value = values[2];
        value_micro = values[3];
        unit_count = 6;
        const source_units = [_]usize{ 0, 1, 3, 4, 5 };
        const target_units = [_]usize{ 1, 2, 1, 1, 0 };
        const slopes = [_]f64{ 1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0 };
        const intercepts = [_]f64{ -273.15, 32.0, 0.0, 100.0, 0.0 };
        for (0..5) |edge| {
            const slot = source_units[edge] * MAX_UNITS + target_units[edge];
            known_present[slot] = 1;
            known_slopes[slot] = slopes[edge];
            known_intercepts[slot] = intercepts[edge];
            known_count += 1;
        }
    } else if (values[0] == 1) {
        if (length < 6) return INVALID_RESULT;
        const unit_count_value = values[1];
        const edge_count = values[2];
        source_value = values[3];
        target_value = values[4];
        value_micro = values[5];
        if (unit_count_value < 2 or unit_count_value > @as(i64, @intCast(MAX_UNITS)) or edge_count < 0 or
            edge_count > unit_count_value - 1 or length != @as(usize, @intCast(6 + 4 * edge_count))) return INVALID_RESULT;
        unit_count = @intCast(unit_count_value);
        var parent: [MAX_UNITS]i64 = @splat(0);
        for (0..unit_count) |unit| parent[unit] = @intCast(unit);
        for (0..@as(usize, @intCast(edge_count))) |edge| {
            const offset = 6 + 4 * edge;
            const from = values[offset];
            const to = values[offset + 1];
            const slope_ppm = values[offset + 2];
            const intercept_micro = values[offset + 3];
            if (from < 0 or from >= unit_count_value or to < 0 or to >= unit_count_value or from == to or
                slope_ppm == 0 or slope_ppm < -MAX_SLOPE_PPM or slope_ppm > MAX_SLOPE_PPM or
                intercept_micro < -MAX_INTERCEPT_MICRO or intercept_micro > MAX_INTERCEPT_MICRO) return INVALID_RESULT;
            const root_from = findRoot(&parent, from);
            const root_to = findRoot(&parent, to);
            if (root_from == root_to) return INVALID_RESULT;
            parent[@intCast(root_from)] = root_to;
            const slot = @as(usize, @intCast(from)) * MAX_UNITS + @as(usize, @intCast(to));
            known_present[slot] = 1;
            known_slopes[slot] = @as(f64, @floatFromInt(slope_ppm)) / 1_000_000.0;
            known_intercepts[slot] = @as(f64, @floatFromInt(intercept_micro)) / 1_000_000.0;
            known_count += 1;
        }
    } else {
        return INVALID_RESULT;
    }

    if (source_value < 0 or source_value >= @as(i64, @intCast(unit_count)) or target_value < 0 or
        target_value >= @as(i64, @intCast(unit_count)) or source_value == target_value or
        value_micro < -MAX_VALUE_MICRO or value_micro > MAX_VALUE_MICRO) return INVALID_RESULT;

    var stable = false;
    for (0..MAX_UNITS + 1) |_| {
        var next_present: [MAX_CONVERSIONS]i64 = @splat(0);
        var next_slopes: [MAX_CONVERSIONS]f64 = @splat(0.0);
        var next_intercepts: [MAX_CONVERSIONS]f64 = @splat(0.0);
        const next_count = addAll(&known_present, &known_slopes, &known_intercepts, unit_count,
            &next_present, &next_slopes, &next_intercepts);
        known_present = next_present;
        known_slopes = next_slopes;
        known_intercepts = next_intercepts;
        if (next_count == known_count) {
            stable = true;
            break;
        }
        known_count = next_count;
    }
    if (!stable) return INVALID_RESULT;
    const result_slot = @as(usize, @intCast(source_value)) * MAX_UNITS + @as(usize, @intCast(target_value));
    if (known_present[result_slot] == 0) return INVALID_RESULT;
    const value = @as(f64, @floatFromInt(value_micro)) / 1_000_000.0;
    return known_slopes[result_slot] * value + known_intercepts[result_slot];
}
