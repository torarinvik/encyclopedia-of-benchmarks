const lists: usize = 3;
const max_list: usize = 32;
const max_values: usize = 48;
const max_input: usize = 3 + lists * max_list;
const white: u8 = 0;
const green: u8 = 1;
const red: u8 = 2;

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn t_threshold_three_sorted_lists(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > max_input + 1) return -1;
    const input = input_opt.?;
    var base = [_]usize{0} ** lists;
    var sizes = [_]usize{0} ** lists;
    var at: usize = 0;
    for (0..lists) |id| {
        if (at >= length or input[at] < 1 or input[at] > max_list) return -1;
        sizes[id] = @intCast(input[at]);
        at += 1;
        if (sizes[id] > length - at) return -1;
        base[id] = at;
        for (0..sizes[id]) |j| {
            const value = input[at + j];
            if (value < -2147483648 or value > 2147483647 or
                (j > 0 and input[at + j - 1] >= value)) return -1;
        }
        at += sizes[id];
    }
    if (at != length) return -1;

    var tails = [_]i64{0} ** lists;
    var firsts = [_]i64{0} ** lists;
    for (0..lists) |i| {
        tails[i] = input[base[i] + sizes[i] - 1];
        firsts[i] = input[base[i]];
    }
    for (0..lists) |i| {
        for (i + 1..lists) |j| {
            if (tails[i] > tails[j]) { const temp = tails[i]; tails[i] = tails[j]; tails[j] = temp; }
            if (firsts[i] > firsts[j]) { const temp = firsts[i]; firsts[i] = firsts[j]; firsts[j] = temp; }
        }
    }
    const maximum_candidate = tails[1];
    var candidate = firsts[1];

    var color = [_]u8{white} ** lists;
    var cursor = [_]usize{1} ** lists;
    var search_base = [_]usize{1} ** lists;
    var search_low = [_]usize{1} ** lists;
    var search_step = [_]usize{1} ** lists;
    var search_probe = [_]usize{1} ** lists;
    var representative = [_]usize{0} ** lists;
    var representative_present = [_]bool{false} ** lists;
    for (0..lists) |i| {
        if (input[base[i]] == candidate) {
            color[i] = green;
        } else if (input[base[i]] > candidate) {
            color[i] = red;
            representative_present[i] = true;
        }
    }

    var result = [_]i64{0} ** max_values;
    var result_count: usize = 0;
    var round_robin: usize = 0;
    while (candidate <= maximum_candidate) {
        var green_count: usize = 0;
        var red_count: usize = 0;
        var white_count: usize = 0;
        for (0..lists) |i| {
            if (color[i] == green) {
                green_count += 1;
            } else if (color[i] == red) {
                red_count += 1;
            } else {
                white_count += 1;
            }
        }
        if (green_count >= 2 or red_count >= 2) {
            if (green_count >= 2) { result[result_count] = candidate; result_count += 1; }
            var recolor_count: usize = 0;
            if (white_count == 0) recolor_count = 1;
            for (0..lists) |i| {
                if (recolor_count == 0) break;
                if (color[i] != green) continue;
                color[i] = white;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
                recolor_count -= 1;
            }
            for (0..lists) |i| {
                if (color[i] != green) continue;
                color[i] = red;
                representative[i] = cursor[i];
                representative_present[i] = cursor[i] < sizes[i];
            }
            var found = false;
            var next_candidate: i64 = 9223372036854775807;
            for (0..lists) |i| {
                if (!representative_present[i]) continue;
                const value = input[base[i] + representative[i]];
                if (!found or value < next_candidate) { found = true; next_candidate = value; }
            }
            if (!found) break;
            candidate = next_candidate;
            for (0..lists) |i| {
                if (color[i] != red or !representative_present[i] or input[base[i] + representative[i]] != candidate) continue;
                color[i] = green;
                representative_present[i] = false;
                cursor[i] = representative[i] + 1;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
            }
            continue;
        }

        var list_id: usize = lists;
        for (0..lists) |offset| {
            const i = (round_robin + offset) % lists;
            if (color[i] == white) { list_id = i; break; }
        }
        if (list_id == lists) break;
        round_robin = (list_id + 1) % lists;
        const probe = @min(search_probe[list_id], sizes[list_id] - 1);
        if (input[base[list_id] + probe] < candidate) {
            search_low[list_id] = probe + 1;
            if (probe + 1 == sizes[list_id]) {
                color[list_id] = red;
                representative[list_id] = sizes[list_id];
                representative_present[list_id] = false;
            } else {
                search_step[list_id] *= 2;
                search_probe[list_id] = @min(search_base[list_id] + search_step[list_id] - 1, sizes[list_id] - 1);
            }
            continue;
        }
        var low = search_low[list_id];
        var high = probe + 1;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (input[base[list_id] + middle] < candidate) {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        if (low < sizes[list_id] and input[base[list_id] + low] == candidate) {
            color[list_id] = green;
            cursor[list_id] = low + 1;
        } else {
            color[list_id] = red;
            representative[list_id] = low;
            representative_present[list_id] = low < sizes[list_id];
        }
    }

    const output_bytes = 8 * (1 + result_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    putI64Le(output, 0, @intCast(result_count));
    for (0..result_count) |i| putI64Le(output, 8 * (i + 1), result[i]);
    return @intCast(output_bytes);
}
