const MAX_OPERATIONS: usize = 128;
const MAX_ELEMENTS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_OPERATIONS;

fn writeI64Le(output: [*]u8, word_index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word_index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn dynamic_array(input: ?[*]const i64, length: usize,
                        output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const operation_count_value = values[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;

    var first: [MAX_ELEMENTS]i64 = @splat(0);
    var second: [MAX_ELEMENTS]i64 = @splat(0);
    var query_results: [MAX_OPERATIONS]i64 = @splat(0);
    var active_first = true;
    var size: usize = 0;
    var capacity: usize = 16;
    var cursor: usize = 1;
    var query_count: usize = 0;
    const operation_count: usize = @intCast(operation_count_value);

    for (0..operation_count) |_| {
        if (cursor >= length) return -1;
        const operation = values[cursor];
        cursor += 1;
        if (operation == 0) {
            if (cursor >= length or size >= MAX_ELEMENTS) return -1;
            const value = values[cursor];
            cursor += 1;
            if (size == capacity) {
                if (active_first) {
                    for (0..size) |index| second[index] = first[index];
                    active_first = false;
                } else {
                    for (0..size) |index| first[index] = second[index];
                    active_first = true;
                }
                capacity *= 2;
            }
            if (active_first) first[size] = value else second[size] = value;
            size += 1;
        } else if (operation == 1) {
            if (cursor + 1 >= length) return -1;
            const index_value = values[cursor];
            const value = values[cursor + 1];
            cursor += 2;
            if (index_value < 0) return -1;
            const index: usize = @intCast(index_value);
            if (index >= size) return -1;
            if (active_first) first[index] = value else second[index] = value;
        } else if (operation == 2) {
            if (cursor >= length or query_count >= MAX_OPERATIONS) return -1;
            const index_value = values[cursor];
            cursor += 1;
            if (index_value < 0) return -1;
            const index: usize = @intCast(index_value);
            if (index >= size) return -1;
            query_results[query_count] = if (active_first) first[index] else second[index];
            query_count += 1;
        } else if (operation == 3) {
            if (query_count >= MAX_OPERATIONS) return -1;
            query_results[query_count] = @intCast(size);
            query_count += 1;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const output_words = 2 + query_count + size;
    const output_bytes = output_words * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const dst = output.?[0..output_bytes];
    writeI64Le(dst.ptr, 0, @intCast(query_count));
    for (0..query_count) |index| writeI64Le(dst.ptr, index + 1, query_results[index]);
    writeI64Le(dst.ptr, query_count + 1, @intCast(size));
    for (0..size) |index| {
        const value = if (active_first) first[index] else second[index];
        writeI64Le(dst.ptr, query_count + 2 + index, value);
    }
    return @intCast(output_words);
}
