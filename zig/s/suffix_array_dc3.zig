const MAX_TEXT_LENGTH: usize = 16;
const MAX_INPUT_LENGTH: usize = 18;

fn symbolAt(symbols: [*]const i64, length: usize, position: usize) i64 {
    return if (position < length) symbols[position] else 0;
}

fn sampleRank(ranks: [*]const i64, length: usize, position: usize) i64 {
    return if (position < length) ranks[position] else -1;
}

fn tripleCompare(symbols: [*]const i64, length: usize, left: usize, right: usize) i32 {
    for (0..3) |offset| {
        const a = symbolAt(symbols, length, left + offset);
        const b = symbolAt(symbols, length, right + offset);
        if (a != b) return if (a < b) -1 else 1;
    }
    return 0;
}

fn suffixCompare(symbols: [*]const i64, length: usize, left_start: usize, right_start: usize) i32 {
    var left = left_start;
    var right = right_start;
    while (left < length and right < length) {
        if (symbols[left] != symbols[right]) return if (symbols[left] < symbols[right]) -1 else 1;
        left += 1;
        right += 1;
    }
    if (left == length and right == length) return 0;
    return if (left == length) -1 else 1;
}

fn zeroPairCompare(symbols: [*]const i64, ranks: [*]const i64, length: usize,
    left: usize, right: usize) i32 {
    const a = symbolAt(symbols, length, left);
    const b = symbolAt(symbols, length, right);
    if (a != b) return if (a < b) -1 else 1;
    const left_rank = sampleRank(ranks, length, left + 1);
    const right_rank = sampleRank(ranks, length, right + 1);
    if (left_rank != right_rank) return if (left_rank < right_rank) -1 else 1;
    return 0;
}

fn mergeCompare(symbols: [*]const i64, ranks: [*]const i64, length: usize,
    zero: usize, sample: usize) i32 {
    const first_zero = symbolAt(symbols, length, zero);
    const first_sample = symbolAt(symbols, length, sample);
    if (first_zero != first_sample) return if (first_zero < first_sample) -1 else 1;
    if (sample % 3 == 1) {
        const a = sampleRank(ranks, length, zero + 1);
        const b = sampleRank(ranks, length, sample + 1);
        if (a != b) return if (a < b) -1 else 1;
    } else {
        const a = symbolAt(symbols, length, zero + 1);
        const b = symbolAt(symbols, length, sample + 1);
        if (a != b) return if (a < b) -1 else 1;
        const c = sampleRank(ranks, length, zero + 2);
        const d = sampleRank(ranks, length, sample + 2);
        if (c != d) return if (c < d) -1 else 1;
    }
    return 0;
}

fn dc3(symbols: [*]const i64, length: usize, suffixes: [*]usize) void {
    if (length == 0) return;
    if (length <= 3) {
        for (0..length) |i| suffixes[i] = i;
        for (1..length) |i| {
            const key = suffixes[i];
            var position = i;
            while (position > 0 and suffixCompare(symbols, length, key, suffixes[position - 1]) < 0) {
                suffixes[position] = suffixes[position - 1];
                position -= 1;
            }
            suffixes[position] = key;
        }
        return;
    }

    var sample_positions: [MAX_TEXT_LENGTH]usize = @splat(0);
    var sample_count: usize = 0;
    for (1..length) |i| {
        if (i % 3 != 0) { sample_positions[sample_count] = i; sample_count += 1; }
    }
    for (1..sample_count) |i| {
        const key = sample_positions[i];
        var position = i;
        while (position > 0 and tripleCompare(symbols, length, key, sample_positions[position - 1]) < 0) {
            sample_positions[position] = sample_positions[position - 1];
            position -= 1;
        }
        sample_positions[position] = key;
    }

    var triple_ranks: [MAX_TEXT_LENGTH]i64 = @splat(0);
    var next_rank: i64 = 0;
    for (0..sample_count) |i| {
        if (i == 0 or tripleCompare(symbols, length, sample_positions[i - 1], sample_positions[i]) != 0) next_rank += 1;
        triple_ranks[sample_positions[i]] = next_rank;
    }
    var group_one_count: usize = 0;
    var i: usize = 1;
    while (i < length) : (i += 3) group_one_count += 1;
    var reduced: [MAX_TEXT_LENGTH]i64 = @splat(0);
    var reduced_length: usize = 0;
    i = 1;
    while (i < length) : (i += 3) { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1; }
    reduced[reduced_length] = 0;
    reduced_length += 1;
    i = 2;
    while (i < length) : (i += 3) { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1; }
    var reduced_order: [MAX_TEXT_LENGTH]usize = @splat(0);
    dc3(&reduced[0], reduced_length, &reduced_order[0]);

    var sample_order: [MAX_TEXT_LENGTH]usize = @splat(0);
    var ranks: [MAX_TEXT_LENGTH]i64 = @splat(-1);
    var sample_order_count: usize = 0;
    for (0..reduced_length) |index| {
        const reduced_position = reduced_order[index];
        if (reduced_position == group_one_count) continue;
        const source_position = if (reduced_position < group_one_count)
            1 + 3 * reduced_position
        else
            2 + 3 * (reduced_position - group_one_count - 1);
        sample_order[sample_order_count] = source_position;
        ranks[source_position] = @intCast(sample_order_count);
        sample_order_count += 1;
    }

    var zero_positions: [MAX_TEXT_LENGTH]usize = @splat(0);
    var zero_count: usize = 0;
    i = 0;
    while (i < length) : (i += 3) { zero_positions[zero_count] = i; zero_count += 1; }
    for (1..zero_count) |index| {
        const key = zero_positions[index];
        var position = index;
        while (position > 0 and zeroPairCompare(symbols, &ranks, length, key, zero_positions[position - 1]) < 0) {
            zero_positions[position] = zero_positions[position - 1];
            position -= 1;
        }
        zero_positions[position] = key;
    }

    var zi: usize = 0;
    var si: usize = 0;
    var oi: usize = 0;
    while (zi < zero_count and si < sample_order_count) {
        const zero = zero_positions[zi];
        const sample = sample_order[si];
        if (mergeCompare(symbols, &ranks, length, zero, sample) < 0) {
            suffixes[oi] = zero_positions[zi]; zi += 1;
        } else {
            suffixes[oi] = sample_order[si]; si += 1;
        }
        oi += 1;
    }
    while (zi < zero_count) { suffixes[oi] = zero_positions[zi]; zi += 1; oi += 1; }
    while (si < sample_order_count) { suffixes[oi] = sample_order[si]; si += 1; oi += 1; }
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn suffix_array_dc3(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (0..count) |i| if (values[i + 1] < 0 or values[i + 1] > 255) return -1;
    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    if (count == 0) return 0;
    var symbols: [MAX_TEXT_LENGTH]i64 = @splat(0);
    for (0..count) |i| symbols[i] = values[i + 1] + 1;
    var suffixes: [MAX_TEXT_LENGTH]usize = @splat(0);
    dc3(&symbols[0], count, &suffixes[0]);
    for (0..count) |i| putI64Le(output, i * 8, @intCast(suffixes[i]));
    return @intCast(output_bytes);
}
