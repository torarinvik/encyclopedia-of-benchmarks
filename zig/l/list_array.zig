const MAX_CAPACITY: usize = 16;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 65;

fn selectionSort(items: *[MAX_CAPACITY]u64, count: usize) void {
    for (0..count) |i| {
        var minimum = i;
        for (i + 1..count) |j| {
            if (items[j] < items[minimum]) minimum = j;
        }
        const value = items[minimum];
        items[minimum] = items[i];
        items[i] = value;
    }
}

fn binarySearch(items: *const [MAX_CAPACITY]u64, first: usize, last: usize, value: u64) i64 {
    if (last < first) return -1;
    const middle = (first + last) / 2;
    if (items[middle] == value) return @intCast(middle);
    if (value < items[middle]) return binarySearch(items, first, middle - 1, value);
    return binarySearch(items, middle + 1, last, value);
}

fn putI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[offset + i] = @truncate(bits >> @as(u6, @intCast(8 * i)));
}

export fn list_array(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const capacity_value = input[0];
    const operation_count_value = input[1];
    if (capacity_value < 1 or capacity_value > 16
        or operation_count_value < 1 or operation_count_value > 64) return -1;
    const capacity: usize = @intCast(capacity_value);
    const operations: usize = @intCast(operation_count_value);
    if (length != 2 + 2 * operations) return -1;

    var opcodes = [_]i64{0} ** MAX_OPERATIONS;
    var arguments = [_]i64{0} ** MAX_OPERATIONS;
    var sorted = false;
    for (0..operations) |i| {
        const opcode = input[2 + 2 * i];
        const argument = input[3 + 2 * i];
        if (opcode == 0) {
            if (sorted or argument < 0) return -1;
        } else if (opcode == 1) {
            if (sorted or argument != 0) return -1;
            sorted = true;
        } else if (opcode == 2 or opcode == 3) {
            if (!sorted or argument < 0) return -1;
        } else return -1;
        opcodes[i] = opcode;
        arguments[i] = argument;
    }
    if (!sorted) return -1;

    var items = [_]u64{0} ** MAX_CAPACITY;
    var results = [_]i64{0} ** MAX_OPERATIONS;
    var output_words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var count: usize = 0;
    var result_count: usize = 0;
    for (0..operations) |i| {
        const opcode = opcodes[i];
        const argument = arguments[i];
        if (opcode == 0) {
            if (count == capacity) return -1;
            items[count] = @intCast(argument);
            count += 1;
        } else if (opcode == 1) {
            selectionSort(&items, count);
        } else {
            if (count == 0 or @as(u64, @intCast(argument)) < items[0]) return -1;
            if (opcode == 3 and count >= capacity) return -1;
            const position = binarySearch(&items, 0, count - 1, @intCast(argument));
            results[result_count] = position;
            result_count += 1;
            if (opcode == 3 and position >= 0) {
                var j: usize = @intCast(position);
                while (j < count) : (j += 1) items[j] = items[j + 1];
                count -= 1;
            }
        }
    }

    var word_count: usize = 0;
    output_words[word_count] = @intCast(result_count);
    word_count += 1;
    for (0..result_count) |i| {
        output_words[word_count] = results[i];
        word_count += 1;
    }
    output_words[word_count] = @intCast(count);
    word_count += 1;
    for (0..count) |i| {
        output_words[word_count] = @intCast(items[i]);
        word_count += 1;
    }
    const required = word_count * 8;
    if (output == null or output_capacity < required) return -2;
    const out: [*]u8 = @ptrCast(output);
    for (0..word_count) |i| putI64LE(out, i * 8, output_words[i]);
    return @intCast(required);
}
