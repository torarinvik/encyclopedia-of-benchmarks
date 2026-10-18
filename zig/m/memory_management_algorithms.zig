const MAX_BLOCK_COUNT: usize = 16;
const MAX_PROCESS_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 52;
const MAX_OUTPUT_BYTES: usize = 256;
const NO_ALLOCATION: i64 = -255;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn memory_management_algorithms(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > 3 or values[1] < 1 or values[1] > MAX_BLOCK_COUNT or
        values[2] < 0 or values[2] > MAX_PROCESS_COUNT) return -1;
    const policy = values[0];
    const block_count: usize = @intCast(values[1]);
    const process_count: usize = @intCast(values[2]);
    if (input_length != 3 + block_count + process_count) return -1;

    var blocks = [_]i64{0} ** MAX_BLOCK_COUNT;
    var processes = [_]i64{0} ** MAX_PROCESS_COUNT;
    for (0..block_count) |index| {
        const size = values[3 + index];
        if (size < 1 or size > 10_000) return -1;
        blocks[index] = size;
    }
    for (0..process_count) |index| {
        const size = values[3 + block_count + index];
        if (size < 1 or size > 10_000) return -1;
        processes[index] = size;
    }

    var allocations = [_]i64{0} ** MAX_PROCESS_COUNT;
    var next_fit_counter: i64 = 0;
    for (0..process_count) |process_index| {
        const process = processes[process_index];
        var selected: i64 = NO_ALLOCATION;
        if (policy == 0) {
            for (0..block_count) |index| {
                if (blocks[index] >= process) { selected = @intCast(index); break; }
            }
        } else if (policy == 1) {
            var min_diff = blocks[0];
            for (1..block_count) |index| {
                if (blocks[index] > min_diff) min_diff = blocks[index];
            }
            for (0..block_count) |index| {
                const difference = blocks[index] - process;
                if (difference < min_diff and difference >= 0) {
                    min_diff = difference;
                    selected = @intCast(index);
                }
            }
        } else if (policy == 2) {
            var best: usize = 0;
            for (1..block_count) |candidate| {
                if (blocks[candidate] > blocks[best]) best = candidate;
            }
            if (blocks[best] >= process) selected = @intCast(best);
        } else {
            var found = false;
            for (0..block_count) |offset| {
                if (next_fit_counter + @as(i64, @intCast(offset)) >= @as(i64, @intCast(block_count)))
                    next_fit_counter = -@as(i64, @intCast(offset));
                const index: usize = @intCast(@as(i64, @intCast(offset)) + next_fit_counter);
                if (blocks[index] >= process) {
                    next_fit_counter += @intCast(offset);
                    selected = next_fit_counter;
                    found = true;
                    break;
                }
            }
            if (!found) next_fit_counter += @intCast(block_count);
        }
        allocations[process_index] = selected;
        if (selected != NO_ALLOCATION) blocks[@intCast(selected)] -= process;
    }

    const output_bytes = process_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const output_ptr = output orelse return -2;
    if (capacity < output_bytes) return -2;
    const output_slice = output_ptr[0..output_bytes];
    for (0..process_count) |index| writeI64Le(output_slice, index * 8, allocations[index]);
    return @intCast(output_bytes);
}
