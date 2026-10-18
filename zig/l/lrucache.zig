const MAX_INPUT_LENGTH: usize = 99;
const MAX_OUTPUT_WORDS: usize = 130;

export fn lrucache(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    const capacity_value = input[0];
    const operation_count_value = input[1];
    if (capacity_value < 2 or capacity_value > 16 or
        operation_count_value < 0 or operation_count_value > 32) return -1;
    const cache_capacity: usize = @intCast(capacity_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (input_length != 2 + 3 * operation_count) return -1;

    var keys = [_]i64{0} ** 16;
    var cached_values = [_]i64{0} ** 16;
    var seen_put_keys = [_]i64{0} ** 32;
    var operation_records = [_]i64{0} ** 96;
    var used: usize = 0;
    var seen_count: usize = 0;

    for (0..operation_count) |operation| {
        const opcode = input[2 + 3 * operation];
        const key = input[3 + 3 * operation];
        const value = input[4 + 3 * operation];
        if (opcode != 0 and opcode != 1) return -1;
        if (key < 0 or key > 1_000_000) return -1;
        var returned_value: i64 = -1;
        var evicted_key: i64 = -1;
        var position: usize = 0;
        while (position < used and keys[position] != key) : (position += 1) {}

        if (opcode == 0) {
            if (value < 0 or value > 1_000_000) return -1;
            for (0..seen_count) |prior| {
                if (seen_put_keys[prior] == key) return -1;
            }
            seen_put_keys[seen_count] = key;
            seen_count += 1;
            if (used == cache_capacity) {
                evicted_key = keys[0];
                for (1..used) |index| {
                    keys[index - 1] = keys[index];
                    cached_values[index - 1] = cached_values[index];
                }
                used -= 1;
            }
            keys[used] = key;
            cached_values[used] = value;
            used += 1;
        } else {
            if (value != 0 or position == used) return -1;
            returned_value = cached_values[position];
            for (position + 1..used) |index| {
                keys[index - 1] = keys[index];
                cached_values[index - 1] = cached_values[index];
            }
            keys[used - 1] = key;
            cached_values[used - 1] = returned_value;
        }
        operation_records[3 * operation] = opcode;
        operation_records[3 * operation + 1] = returned_value;
        operation_records[3 * operation + 2] = evicted_key;
    }

    var fields = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    fields[word_count] = operation_count_value;
    word_count += 1;
    for (0..3 * operation_count) |index| {
        fields[word_count] = operation_records[index];
        word_count += 1;
    }
    fields[word_count] = @intCast(used);
    word_count += 1;
    for (0..used) |offset| {
        const index = used - 1 - offset;
        fields[word_count] = keys[index];
        fields[word_count + 1] = cached_values[index];
        word_count += 2;
    }

    const output_bytes = word_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..word_count) |index| {
        const bits: u64 = @bitCast(fields[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
