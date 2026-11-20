const max_n: usize = 8;
const rounds: usize = 24;
const max_groups: usize = 8;
const max_output_words: usize = 7;

fn truth_at(table: *const [4]u64, point: u32) i64 {
    const word: usize = @intCast(point / 64);
    const bit: u6 = @intCast(point % 64);
    return @intCast((table[word] >> bit) & 1);
}

fn put_i64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn junta_test_partition_binary_search(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 40) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const group_value = input[1];
    const table_count_value = input[2];
    if (n_value < 1 or n_value > max_n or group_value < 1 or group_value > n_value) return -1;
    const n: usize = @intCast(n_value);
    const group_count: usize = @intCast(group_value);
    const domain: usize = @as(usize, 1) << @intCast(n);
    const truth_words = (domain + 63) / 64;
    if (table_count_value != @as(i64, @intCast(truth_words))) return -1;
    const table_at: usize = 3;
    const labels_at = table_at + truth_words;
    const tape_at = labels_at + n;
    if (length != tape_at + rounds) return -1;

    var table: [4]u64 = @splat(0);
    for (0..truth_words) |word| table[word] = @bitCast(input[table_at + word]);
    const tail_bits = domain % 64;
    if (tail_bits != 0 and (table[truth_words - 1] >> @intCast(tail_bits)) != 0) return -1;

    var group_masks: [max_groups]u32 = @splat(0);
    var groups_seen: u32 = 0;
    for (0..n) |coordinate| {
        const group = input[labels_at + coordinate];
        if (group < 0 or group >= group_value) return -1;
        const group_index: usize = @intCast(group);
        group_masks[group_index] |= @as(u32, 1) << @intCast(coordinate);
        groups_seen |= @as(u32, 1) << @intCast(group_index);
    }
    if (groups_seen != (@as(u32, 1) << @intCast(group_count)) - 1) return -1;
    const pair_limit: u64 = @as(u64, 1) << @intCast(2 * n);
    for (0..rounds) |round| {
        const pair = input[tape_at + round];
        if (pair < 0 or @as(u64, @intCast(pair)) >= pair_limit) return -1;
    }

    var result: [max_output_words]i64 = @splat(0);
    var event_rounds: [2]i64 = @splat(0);
    var event_groups: [2]i64 = @splat(0);
    var found: usize = 0;
    var query_count: usize = 0;
    const all_coordinates: u32 = (@as(u32, 1) << @intCast(n)) - 1;
    var active = all_coordinates;
    for (0..rounds) |round| {
        const packed: u64 = @intCast(input[tape_at + round]);
        const x: u32 = @intCast(packed & all_coordinates);
        const y: u32 = @intCast((packed >> @intCast(n)) & all_coordinates);
        const hybrid = (x & ~active) | (y & active);
        var left_value = truth_at(&table, x);
        const right_value = truth_at(&table, hybrid);
        query_count += 2;
        if (left_value == right_value) continue;

        var candidates: [max_groups]u8 = @splat(0);
        var candidate_count: usize = 0;
        for (0..group_count) |group| {
            if ((group_masks[group] & active) != 0) {
                candidates[candidate_count] = @intCast(group);
                candidate_count += 1;
            }
        }
        var left_endpoint = x;
        var right_endpoint = hybrid;
        while (candidate_count > 1) {
            const cut = candidate_count / 2;
            var low_mask: u32 = 0;
            for (0..cut) |i| low_mask |= group_masks[candidates[i]];
            const probe = (left_endpoint & ~low_mask) | (right_endpoint & low_mask);
            const probe_value = truth_at(&table, probe);
            query_count += 1;
            if (probe_value != left_value) {
                right_endpoint = probe;
                candidate_count = cut;
            } else {
                left_endpoint = probe;
                left_value = probe_value;
                for (cut..candidate_count) |i| candidates[i - cut] = candidates[i];
                candidate_count -= cut;
            }
        }
        const selected: usize = candidates[0];
        active &= ~group_masks[selected];
        event_rounds[found] = @intCast(round);
        event_groups[found] = @intCast(selected);
        found += 1;
        if (found > 1) break;
    }

    result[0] = if (found > 1) 1 else 0;
    result[1] = @intCast(found);
    result[2] = @intCast(query_count);
    for (0..found) |i| {
        result[3 + 2 * i] = event_rounds[i];
        result[4 + 2 * i] = event_groups[i];
    }
    const result_words = 3 + 2 * found;
    const result_bytes = result_words * 8;
    if (output_opt == null or capacity < result_bytes) return -2;
    const output = output_opt.?;
    for (0..result_words) |i| put_i64(output, i * 8, result[i]);
    return @intCast(result_bytes);
}
