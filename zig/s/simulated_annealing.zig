const MAX_PACKED_LENGTH: usize = 366;
const MAX_DRAWS: i64 = 176;
const MAX_ITERATIONS: usize = 22;
const INVALID_RESULT: i64 = -1;

fn scoreI64(x: i64, y: i64) i64 { return x * x + y * y; }

export fn simulated_annealing(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 13 or length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const x0 = values[0];
    const y0 = values[1];
    const step = values[2];
    const min_x = values[3];
    const max_x = values[4];
    const min_y = values[5];
    const max_y = values[6];
    const find_max = values[7];
    const start_raw = values[8];
    const rate_raw = values[9];
    const threshold_raw = values[10];
    const selection_count = values[11];
    if (x0 < -16 or x0 > 16 or y0 < -16 or y0 > 16 or step < 1 or step > 4 or
        min_x < -16 or max_x > 16 or min_x > max_x or min_y < -16 or max_y > 16 or min_y > max_y or
        x0 < min_x or x0 > max_x or y0 < min_y or y0 > max_y or (find_max != 0 and find_max != 1) or
        start_raw < 1_000_000 or start_raw > 10_000_000 or rate_raw < 100_000 or rate_raw > 500_000 or
        threshold_raw < 1_000_000 or threshold_raw > 9_999_999 or threshold_raw >= start_raw or
        selection_count < 0 or selection_count > MAX_DRAWS or @as(usize, @intCast(selection_count)) > length - 13) return INVALID_RESULT;
    const selection_n: usize = @intCast(selection_count);
    const acceptance_count_index = 12 + selection_n;
    const acceptance_count = values[acceptance_count_index];
    if (acceptance_count < 0 or acceptance_count > MAX_DRAWS or
        length != 13 + selection_n + @as(usize, @intCast(acceptance_count))) return INVALID_RESULT;
    for (0..selection_n) |i| if (values[12 + i] < 0 or values[12 + i] > 7) return INVALID_RESULT;
    const acceptance_start = acceptance_count_index + 1;
    for (0..@as(usize, @intCast(acceptance_count))) |i| {
        const draw = values[acceptance_start + i];
        if (draw != 0 and draw != 999_999) return INVALID_RESULT;
    }

    var current_temp = @as(f64, @floatFromInt(start_raw)) / 1_000_000.0;
    const rate = @as(f64, @floatFromInt(rate_raw)) / 1_000_000.0;
    const threshold = @as(f64, @floatFromInt(threshold_raw)) / 1_000_000.0;
    var current_x = x0;
    var current_y = y0;
    var best_x = x0;
    var best_y = y0;
    var best_score = scoreI64(x0, y0);
    var selection_cursor: usize = 0;
    var acceptance_cursor: usize = 0;
    var stopped = false;

    for (0..MAX_ITERATIONS) |_| {
        const current_score = scoreI64(current_x, current_y);
        if (current_score > best_score) { best_score = current_score; best_x = current_x; best_y = current_y; }
        var nx = [8]i64{current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step};
        var ny = [8]i64{current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step};
        var remaining: usize = 8;
        var found = false;
        var next_x: i64 = 0;
        var next_y: i64 = 0;
        while (!found and remaining > 0) {
            if (selection_cursor >= selection_n) return INVALID_RESULT;
            const rank = values[12 + selection_cursor];
            selection_cursor += 1;
            if (rank < 0 or rank > 7) return INVALID_RESULT;
            const selected: usize = @intCast(rank);
            if (selected >= remaining) return INVALID_RESULT;
            const candidate_x = nx[selected];
            const candidate_y = ny[selected];
            const raw_change = scoreI64(candidate_x, candidate_y) - current_score;
            for (selected + 1..remaining) |i| { nx[i - 1] = nx[i]; ny[i - 1] = ny[i]; }
            remaining -= 1;
            if (candidate_x < min_x or candidate_x > max_x or candidate_y < min_y or candidate_y > max_y) continue;
            const change = if (find_max == 1) raw_change else -raw_change;
            if (change > 0) found = true else {
                if (acceptance_cursor >= @as(usize, @intCast(acceptance_count))) return INVALID_RESULT;
                const draw = values[acceptance_start + acceptance_cursor];
                acceptance_cursor += 1;
                if (change == 0 or draw == 0) found = true;
            }
            if (found) { next_x = candidate_x; next_y = candidate_y; }
        }
        current_temp = current_temp - current_temp * rate;
        if (current_temp < threshold or !found) { stopped = true; break; }
        current_x = next_x;
        current_y = next_y;
    }
    if (!stopped) return INVALID_RESULT;
    return (best_x + 16) * 33 + (best_y + 16);
}
