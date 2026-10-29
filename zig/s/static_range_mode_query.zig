const MAX_N: usize = 32;
const MAX_Q: usize = 16;
const MAX_BLOCKS: usize = 6;
const MAX_INPUT_LENGTH: usize = 66;

fn lowerBoundI64(values: []const i64, target: i64) usize {
    var begin: usize = 0;
    var end = values.len;
    while (begin < end) {
        const middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1 else end = middle;
    }
    return begin;
}

fn lowerBoundUsize(values: []const usize, begin_value: usize,
                   end_value: usize, target: usize) usize {
    var begin = begin_value;
    var end = end_value;
    while (begin < end) {
        const middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1 else end = middle;
    }
    return begin;
}

fn rangeFrequency(occurrences: []const usize, offsets: []const usize,
                  id: usize, left: usize, right: usize) usize {
    const begin = offsets[id];
    const end = offsets[id + 1];
    return lowerBoundUsize(occurrences, begin, end, right) -
        lowerBoundUsize(occurrences, begin, end, left);
}

fn writeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> (8 * byte));
}

export fn static_range_mode_query(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const q_value = values[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        q_value < 1 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 2 * q) return -1;
    for (0..n) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 1_000_000_000) return -1;
    }
    for (0..q) |query| {
        const left = values[2 + n + 2 * query];
        const right = values[3 + n + 2 * query];
        if (left < 0 or right <= left or right > n_value) return -1;
    }
    if (output == null or output_capacity < 16 * q) return -2;

    var sorted = [_]i64{0} ** MAX_N;
    var unique_values = [_]i64{0} ** MAX_N;
    var compressed = [_]usize{0} ** MAX_N;
    var frequencies = [_]usize{0} ** MAX_N;
    var offsets = [_]usize{0} ** (MAX_N + 1);
    var cursor = [_]usize{0} ** MAX_N;
    var occurrences = [_]usize{0} ** MAX_N;
    var block_mode = [_]usize{0} ** (MAX_BLOCKS * MAX_BLOCKS);
    for (0..n) |index| {
        const value = values[2 + index];
        var position = index;
        while (position > 0 and sorted[position - 1] > value) {
            sorted[position] = sorted[position - 1];
            position -= 1;
        }
        sorted[position] = value;
    }
    var distinct: usize = 0;
    for (0..n) |index| {
        if (distinct == 0 or sorted[index] != unique_values[distinct - 1]) {
            unique_values[distinct] = sorted[index];
            distinct += 1;
        }
    }
    for (0..n) |index| {
        const id = lowerBoundI64(unique_values[0..distinct], values[2 + index]);
        compressed[index] = id;
        frequencies[id] += 1;
    }
    for (0..distinct) |id| offsets[id + 1] = offsets[id] + frequencies[id];
    for (0..distinct) |id| cursor[id] = offsets[id];
    for (0..n) |index| {
        const id = compressed[index];
        occurrences[cursor[id]] = index;
        cursor[id] += 1;
    }

    var block_size: usize = 1;
    while (block_size * block_size < n) block_size += 1;
    const block_count = (n + block_size - 1) / block_size;
    var frequency = [_]usize{0} ** MAX_N;
    for (0..block_count) |first| {
        @memset(frequency[0..], 0);
        var best_id: usize = 0;
        var best_count: usize = 0;
        for (first..block_count) |last| {
            const begin = last * block_size;
            const end = @min(n, begin + block_size);
            for (begin..end) |index| {
                const id = compressed[index];
                frequency[id] += 1;
                const count = frequency[id];
                if (count > best_count or (count == best_count and id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            block_mode[first * MAX_BLOCKS + last] = best_id;
        }
    }

    const output_bytes = output.?;
    for (0..q) |query| {
        const left: usize = @intCast(values[2 + n + 2 * query]);
        const right: usize = @intCast(values[3 + n + 2 * query]);
        const first_full = (left + block_size - 1) / block_size;
        const after_full = right / block_size;
        var best_id: usize = 0;
        var best_count: usize = 0;
        if (first_full < after_full) {
            best_id = block_mode[first_full * MAX_BLOCKS + after_full - 1];
            best_count = rangeFrequency(occurrences[0..], offsets[0..], best_id, left, right);
            const span_start = first_full * block_size;
            const span_end = after_full * block_size;
            for (left..span_start) |index| {
                const id = compressed[index];
                const count = rangeFrequency(occurrences[0..], offsets[0..], id, left, right);
                if (count > best_count or (count == best_count and id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            for (span_end..right) |index| {
                const id = compressed[index];
                const count = rangeFrequency(occurrences[0..], offsets[0..], id, left, right);
                if (count > best_count or (count == best_count and id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        } else {
            for (left..right) |index| {
                const id = compressed[index];
                const count = rangeFrequency(occurrences[0..], offsets[0..], id, left, right);
                if (count > best_count or (count == best_count and id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        }
        writeI64(output_bytes, 16 * query, unique_values[best_id]);
        writeI64(output_bytes, 16 * query + 8, @intCast(best_count));
    }
    return @intCast(16 * q);
}
