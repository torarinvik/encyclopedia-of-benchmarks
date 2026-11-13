const QUEUE_CAPACITY: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 65;
const VALUE_MIN: i64 = -1000;
const VALUE_MAX: i64 = 1000;
const CHECKSUM_OFFSET: i64 = 1001;

export fn minimum_queue_two_stacks(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 32) return -1;

    var in_values: [QUEUE_CAPACITY]i64 = [_]i64{0} ** QUEUE_CAPACITY;
    var in_minimums: [QUEUE_CAPACITY]i64 = [_]i64{0} ** QUEUE_CAPACITY;
    var out_values: [QUEUE_CAPACITY]i64 = [_]i64{0} ** QUEUE_CAPACITY;
    var out_minimums: [QUEUE_CAPACITY]i64 = [_]i64{0} ** QUEUE_CAPACITY;
    var in_count: usize = 0;
    var out_count: usize = 0;
    var cursor: usize = 1;
    const operation_count: usize = @intCast(input[0]);
    var checksum: i64 = 0;

    for (0..operation_count) |operation| {
        if (cursor >= length) return -1;
        const opcode = input[cursor];
        cursor += 1;
        if (opcode == 0) {
            if (cursor >= length) return -1;
            const value = input[cursor];
            cursor += 1;
            if (value < VALUE_MIN or value > VALUE_MAX or in_count + out_count >= QUEUE_CAPACITY) return -1;
            in_values[in_count] = value;
            if (in_count == 0 or value < in_minimums[in_count - 1]) {
                in_minimums[in_count] = value;
            } else {
                in_minimums[in_count] = in_minimums[in_count - 1];
            }
            in_count += 1;
        } else if (opcode == 1) {
            if (in_count + out_count == 0) return -1;
            if (out_count == 0) {
                while (in_count > 0) {
                    in_count -= 1;
                    const value = in_values[in_count];
                    out_values[out_count] = value;
                    if (out_count == 0 or value < out_minimums[out_count - 1]) {
                        out_minimums[out_count] = value;
                    } else {
                        out_minimums[out_count] = out_minimums[out_count - 1];
                    }
                    out_count += 1;
                }
            }
            out_count -= 1;
            checksum += (@as(i64, @intCast(operation)) + 1) *
                (out_values[out_count] + CHECKSUM_OFFSET);
        } else if (opcode == 2) {
            if (in_count + out_count == 0) return -1;
            var observed: i64 = 0;
            if (in_count == 0) {
                observed = out_minimums[out_count - 1];
            } else if (out_count == 0) {
                observed = in_minimums[in_count - 1];
            } else if (in_minimums[in_count - 1] < out_minimums[out_count - 1]) {
                observed = in_minimums[in_count - 1];
            } else {
                observed = out_minimums[out_count - 1];
            }
            checksum += (@as(i64, @intCast(operation)) + 1) * (observed + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    var position: i64 = 0;
    var index = out_count;
    while (index > 0) {
        index -= 1;
        position += 1;
        checksum += position * (out_values[index] + CHECKSUM_OFFSET);
    }
    for (0..in_count) |input_index| {
        position += 1;
        checksum += position * (in_values[input_index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
