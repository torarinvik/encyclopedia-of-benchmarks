const MAX_CAPACITY: usize = 16;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 3 * MAX_OPERATIONS;

fn append(words: *[MAX_OUTPUT_WORDS]i64, count: *usize, value: i64) void {
    words[count.*] = value;
    count.* += 1;
}

fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lfu(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 16 or input[1] < 0 or input[1] > 32) return -1;

    const cache_capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[1]);
    var keys = [_]i32{0} ** MAX_CAPACITY;
    var values = [_]i32{0} ** MAX_CAPACITY;
    var size: usize = 0;
    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    var position: usize = 2;

    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = input[position];
        position += 1;
        if (opcode == 0) {
            if (position + 1 >= length) return -1;
            const key_arg = input[position];
            const value_arg = input[position + 1];
            position += 2;
            if (key_arg < -2147483648 or key_arg > 2147483647 or
                value_arg < -2147483648 or value_arg > 2147483647) return -1;
            const key: i32 = @intCast(key_arg);
            var index: usize = 0;
            while (index < size and keys[index] != key) : (index += 1) {}
            if (index < size) {
                // The pinned Put mutates a copied item; the old value remains.
                const old_key = keys[index];
                const old_value = values[index];
                var i = index;
                while (i > 0) : (i -= 1) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = old_key;
                values[0] = old_value;
            } else {
                if (size == cache_capacity) size -= 1;
                var i = size;
                while (i > 0) : (i -= 1) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key;
                values[0] = @intCast(value_arg);
                size += 1;
            }
            append(&words, &word_count, 0);
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const key_arg = input[position];
            position += 1;
            if (key_arg < -2147483648 or key_arg > 2147483647) return -1;
            const key: i32 = @intCast(key_arg);
            var index: usize = 0;
            while (index < size and keys[index] != key) : (index += 1) {}
            append(&words, &word_count, 1);
            if (index == size) {
                append(&words, &word_count, 1);
                append(&words, &word_count, 0);
            } else {
                const value = values[index];
                var i = index;
                while (i > 0) : (i -= 1) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key;
                values[0] = value;
                append(&words, &word_count, 0);
                append(&words, &word_count, value);
            }
        } else {
            return -1;
        }
    }
    if (position != length or word_count > MAX_OUTPUT_WORDS) return -1;
    const output_length = word_count * 8;
    const output = output_opt orelse return -2;
    if (output_capacity < output_length) return -2;
    for (0..word_count) |i| put_i64_le(output, i * 8, words[i]);
    return @intCast(output_length);
}
