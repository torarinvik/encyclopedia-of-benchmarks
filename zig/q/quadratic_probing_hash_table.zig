const MAX_OPERATIONS: usize = 24;
const MAX_INITIAL_CAPACITY: usize = 8;
const MAX_TABLE_CAPACITY: usize = 64;
const MAX_INPUT_LENGTH: usize = 51;
const MAX_OUTPUT_BYTES: usize = 600;

const Table = struct {
    slots: [MAX_TABLE_CAPACITY]i64 = [_]i64{0} ** MAX_TABLE_CAPACITY,
    capacity: usize,
    size: usize = 0,
};

fn probeInsert(table: *const Table, key: i64) ?usize {
    for (0..table.capacity * 100) |probe| {
        const index = (@as(usize, @intCast(key)) + probe * probe) % table.capacity;
        if (table.slots[index] == 0 or table.slots[index] == -1) return index;
    }
    return null;
}

fn probeFind(table: *const Table, key: i64) ?usize {
    for (0..table.capacity * 100) |probe| {
        const index = (@as(usize, @intCast(key)) + probe * probe) % table.capacity;
        const slot = table.slots[index];
        if (slot == 0) return null;
        if (slot == key) return index;
    }
    return null;
}

fn insertKey(table: *Table, key: i64) bool {
    const index = probeInsert(table, key) orelse return false;
    table.slots[index] = key;
    table.size += 1;
    if (table.size * 2 >= table.capacity) return rehash(table);
    return true;
}

fn rehash(table: *Table) bool {
    const old_capacity = table.capacity;
    if (old_capacity > MAX_TABLE_CAPACITY / 2) return false;
    const old_slots = table.slots;
    table.capacity = old_capacity * 2;
    @memset(table.slots[0..table.capacity], 0);
    for (old_slots[0..old_capacity]) |key| {
        if (key == 0 or key == -1) continue;
        if (table.size == 0) return false;
        table.size -= 1;
        if (!insertKey(table, key)) return false;
    }
    return true;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn quadratic_probing_hash_table(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 or values[0] > MAX_INITIAL_CAPACITY or
        values[1] < 0 or values[1] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values[1]);
    if (input_length != 2 + 2 * operation_count) return -1;

    var table = Table{ .capacity = @intCast(values[0]) };
    var active = [_]bool{false} ** (MAX_TABLE_CAPACITY + 1);
    var find_results = [_]i64{0} ** MAX_OPERATIONS;
    var find_count: usize = 0;
    for (0..operation_count) |operation_index| {
        const operation = values[2 + 2 * operation_index];
        const key = values[3 + 2 * operation_index];
        if (operation < 0 or operation > 2 or key < 1 or key > 64) return -1;
        const key_index: usize = @intCast(key);
        if (operation == 0) {
            if (active[key_index] or !insertKey(&table, key)) return -1;
            active[key_index] = true;
        } else if (operation == 1) {
            if (!active[key_index]) return -1;
            const index = probeFind(&table, key) orelse return -1;
            table.slots[index] = -1;
            active[key_index] = false;
            table.size -= 1;
        } else {
            const index = probeFind(&table, key);
            find_results[find_count] = if (index == null or index.? == 0) 0 else table.slots[index.?];
            find_count += 1;
        }
    }

    const output_words = 3 + find_count + table.capacity;
    const output_bytes = output_words * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const output_ptr = output orelse return -2;
    if (capacity < output_bytes) return -2;
    const output_slice = output_ptr[0..output_bytes];
    writeI64Le(output_slice, 0, @intCast(table.capacity));
    writeI64Le(output_slice, 8, @intCast(table.size));
    writeI64Le(output_slice, 16, @intCast(find_count));
    for (0..find_count) |index| writeI64Le(output_slice, (3 + index) * 8, find_results[index]);
    for (0..table.capacity) |index| writeI64Le(output_slice, (3 + find_count + index) * 8, table.slots[index]);
    return @intCast(output_bytes);
}
