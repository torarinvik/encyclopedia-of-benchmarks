const MAX_N: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 258;

fn blockSizeFor(n: usize) usize {
    var block_size: usize = 1;
    while ((block_size + 1) * (block_size + 1) <= n) : (block_size += 1) {}
    return block_size;
}

fn querySum(elements: []const i64, blocks: []const i64, block_size: usize,
            start: usize, ending: usize) i64 {
    const first_index_next_block = ((start / block_size) + 1) * block_size;
    var sum = elements[start];
    if (first_index_next_block > ending) {
        for (start + 1..ending) |index| sum += elements[index];
    } else {
        for (start + 1..first_index_next_block) |index| sum += elements[index];
        const end_block = ending / block_size;
        for (first_index_next_block / block_size..end_block) |block| sum += blocks[block];
        for (end_block * block_size..ending) |index| sum += elements[index];
    }
    return sum;
}

export fn sqrt_decomposition_range_sum(input: [*]const i64, length: usize,
    output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > 64) return -1;
    const n: usize = @intCast(n_value);
    if (length < n + 2) return -1;
    const operation_count_value = input[n + 1];
    if (operation_count_value < 0 or operation_count_value > 64) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 2 + n + 3 * operation_count) return -1;

    var elements: [MAX_N]i64 = undefined;
    for (0..n) |index| {
        const value = input[index + 1];
        if (value < -1000 or value > 1000) return -1;
        elements[index] = value;
    }
    const operations_start = n + 2;
    var query_count: usize = 0;
    for (0..operation_count) |operation| {
        const offset = operations_start + 3 * operation;
        const kind = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        if (kind == 0) {
            if (first < 0 or first >= second or second > n_value) return -1;
            query_count += 1;
        } else if (kind == 1) {
            if (first < 0 or first >= n_value or second < -1000 or second > 1000) return -1;
        } else return -1;
    }

    const output_bytes = query_count * 8;
    if (@intFromPtr(output) == 0 or capacity < output_bytes) return -2;
    const block_size = blockSizeFor(n);
    var blocks: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    for (0..n) |index| {
        const block = index / block_size;
        if (index % block_size == 0) blocks[block] = elements[index]
        else blocks[block] += elements[index];
    }

    var output_offset: usize = 0;
    for (0..operation_count) |operation| {
        const offset = operations_start + 3 * operation;
        const kind = input[offset];
        const first_value = input[offset + 1];
        const second = input[offset + 2];
        if (kind == 0) {
            const sum = querySum(elements[0..n], blocks[0..n], block_size,
                @intCast(first_value), @intCast(second));
            const bits: u64 = @bitCast(sum);
            for (0..8) |byte| output[output_offset + byte] = @truncate(bits >> @intCast(8 * byte));
            output_offset += 8;
        } else {
            const index: usize = @intCast(first_value);
            const block = index / block_size;
            blocks[block] = blocks[block] - elements[index] + second;
            elements[index] = second;
        }
    }
    return @intCast(output_bytes);
}

