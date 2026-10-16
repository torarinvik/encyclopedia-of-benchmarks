const max_years: usize = 16;
const max_value_micro: i64 = 1_000_000_000_000;
const max_rate_ppm: i64 = 1_000_000;
const max_units: i64 = 1_000_000_000;

fn write_f64_le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn min_f64(left: f64, right: f64) f64 { return if (left < right) left else right; }
fn max_f64(left: f64, right: f64) f64 { return if (left > right) left else right; }

export fn depreciation(values: [*c]const i64, length: usize,
                       output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > max_years + 4) return -1;
    const method = values[0];
    var years: usize = 0;
    var purchase_scaled: i64 = 0;
    var residual_scaled: i64 = 0;
    var rate: f64 = 0.0;
    if (method == 0 or method == 3 or method == 4) {
        if (length != 4 or values[1] < 1 or values[1] > max_years) return -1;
        years = @intCast(values[1]);
        purchase_scaled = values[2]; residual_scaled = values[3];
    } else if (method == 1) {
        if (length != 5 or values[1] < 1 or values[1] > max_years
            or values[4] < 1 or values[4] > max_rate_ppm) return -1;
        years = @intCast(values[1]);
        purchase_scaled = values[2]; residual_scaled = values[3];
        rate = @as(f64, @floatFromInt(values[4])) / 1_000_000.0;
    } else if (method == 2) {
        if (length < 5) return -1;
        years = length - 4;
        if (years > max_years or values[3] < 1 or values[3] > max_units) return -1;
        purchase_scaled = values[1]; residual_scaled = values[2];
        var unit_sum: f64 = 0.0;
        for (0..years) |i| {
            if (values[4 + i] < -max_units or values[4 + i] > max_units) return -1;
            unit_sum += @as(f64, @floatFromInt(values[4 + i]));
        }
        if (@abs(unit_sum - @as(f64, @floatFromInt(values[3]))) >
            1.0e-6 * @as(f64, @floatFromInt(values[3]))) return -1;
    } else return -1;

    if (purchase_scaled < 0 or purchase_scaled > max_value_micro
        or residual_scaled < -max_value_micro or residual_scaled > purchase_scaled) return -1;
    const purchase = @as(f64, @floatFromInt(purchase_scaled)) / 1_000_000.0;
    const residual = @as(f64, @floatFromInt(residual_scaled)) / 1_000_000.0;
    const depreciable_cost = purchase - residual;
    var schedule: [max_years]f64 = @splat(0.0);

    if (method == 0) {
        const annual = depreciable_cost / @as(f64, @floatFromInt(years));
        var accumulated: f64 = 0.0;
        for (0..years) |period| {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated
            else { accumulated += annual; schedule[period] = annual; }
        }
    } else if (method == 1) {
        var book_value = purchase;
        for (0..years) |period| {
            if (period == years - 1) schedule[period] = book_value - residual
            else {
                const expense = min_f64(book_value * rate, book_value - residual);
                schedule[period] = expense;
                book_value -= expense;
            }
        }
    } else if (method == 2) {
        const per_unit = depreciable_cost / @as(f64, @floatFromInt(values[3]));
        var accumulated: f64 = 0.0;
        for (0..years) |period| {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated
            else {
                const expense = @as(f64, @floatFromInt(values[4 + period])) * per_unit;
                accumulated += expense; schedule[period] = expense;
            }
        }
    } else if (method == 3) {
        const years_f64 = @as(f64, @floatFromInt(years));
        const syd = years_f64 * (years_f64 + 1.0) / 2.0;
        var accumulated: f64 = 0.0;
        for (1..years + 1) |period| {
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated
            else {
                const remaining = @as(f64, @floatFromInt(years - period + 1));
                const expense = (remaining / syd) * depreciable_cost;
                accumulated += expense; schedule[period - 1] = expense;
            }
        }
    } else {
        const ddb_rate = 2.0 / @as(f64, @floatFromInt(years));
        var book_value = purchase;
        var accumulated: f64 = 0.0;
        for (1..years + 1) |period| {
            const remaining = @as(f64, @floatFromInt(years - period + 1));
            const ddb = max_f64(book_value * ddb_rate, 0.0);
            const straight_line = max_f64((book_value - residual) / remaining, 0.0);
            const expense = min_f64(max_f64(ddb, straight_line), book_value - residual);
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated
            else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense; }
        }
    }

    const output_bytes = years * 8;
    if (output == null or output_bytes > output_capacity) return -2;
    for (0..years) |i| write_f64_le(output, i * 8, schedule[i]);
    return @intCast(output_bytes);
}
