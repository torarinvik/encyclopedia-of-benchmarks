const MAX_TABLE_CAPACITY: usize = 128;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_OUTPUT_WORDS: usize = 1088;
const MAX_KEY: i64 = 2147483520;

fn find_slot(table: *const [MAX_TABLE_CAPACITY]i32, capacity: usize, key: i32) ?usize {
    var index: usize = @intCast(key);
    index %= capacity;
    for (0..capacity) |_| {
        if (table[index] == 0) return null;
        if (table[index] == key) return index;
        index = (index + 1) % capacity;
    }
    return null;
}

fn insertion_slot(table: *const [MAX_TABLE_CAPACITY]i32, capacity: usize, key: i32) ?usize {
    var index: usize = @intCast(key);
    index %= capacity;
    for (0..capacity) |_| {
        if (table[index] == 0 or table[index] == -1) return index;
        index = (index + 1) % capacity;
    }
    return null;
}

fn rehash(table: *[MAX_TABLE_CAPACITY]i32, capacity: *usize) void {
    const old_table = table.*;
    const old_capacity = capacity.*;
    capacity.* *= 2;
    for (0..capacity.*) |i| table[i] = 0;
    for (0..old_capacity) |i| {
        const key = old_table[i];
        if (key <= 0) continue;
        const slot = insertion_slot(table, capacity.*, key) orelse continue;
        table[slot] = key;
    }
}

export fn linear_probing_hash_table(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 16 or input[1] < 0 or input[1] > MAX_OPERATIONS) return -1;
    var table_capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[1]);
    var table: [MAX_TABLE_CAPACITY]i32 = [_]i32{0} ** MAX_TABLE_CAPACITY;
    var size: usize = 0;
    var words: [MAX_OUTPUT_WORDS]i64 = undefined;
    var word_count: usize = 0;
    var position: usize = 2;
    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = input[position]; position += 1;
        if (opcode >= 0 and opcode <= 3) {
            if (position >= length) return -1;
            const key_arg = input[position]; position += 1;
            if (key_arg < 1 or key_arg > MAX_KEY) return -1;
            const key: i32 = @intCast(key_arg);
            if (opcode == 0) {
                const slot = insertion_slot(&table, table_capacity, key) orelse return -1;
                table[slot] = key; size += 1;
                words[word_count] = 0; words[word_count + 1] = 1; word_count += 2;
                if (size * 2 >= table_capacity) rehash(&table, &table_capacity);
            } else if (opcode == 1) {
                const slot = find_slot(&table, table_capacity, key) orelse return -1;
                table[slot] = -1; size -= 1;
                words[word_count] = 1; words[word_count + 1] = 1; word_count += 2;
            } else if (opcode == 2) {
                words[word_count] = 2;
                words[word_count + 1] = if (find_slot(&table, table_capacity, key) != null) 1 else 0;
                word_count += 2;
            } else {
                words[word_count] = 3; words[word_count + 1] = key; word_count += 2;
            }
        } else if (opcode == 4) {
            words[word_count] = 4; words[word_count + 1] = @intCast(table_capacity); word_count += 2;
            for (0..table_capacity) |i| {
                words[word_count] = if (table[i] == 0) -2 else table[i];
                word_count += 1;
            }
        } else return -1;
    }
    if (position != length or word_count > MAX_OUTPUT_WORDS) return -1;
    const output_length = word_count * 8;
    const output = output_opt orelse return -2;
    if (output_capacity < output_length) return -2;
    for (0..word_count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(output_length);
}
