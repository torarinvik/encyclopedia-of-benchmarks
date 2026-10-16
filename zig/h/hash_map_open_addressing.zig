const MAX_OPERATIONS: usize = 256;
const MAX_KEYS: usize = 64;
const MAX_CAPACITY: usize = 1024;
const VALUE_OFFSET: i64 = 1_000_001;

const Entry = struct { state: u8 = 0, key: i64 = 0, value: i64 = 0 };

fn place(table: *[MAX_CAPACITY]Entry, capacity: usize, key: i64, value: i64) void {
    var index: usize = @intCast(@mod(key, @as(i64, @intCast(capacity))));
    for (0..capacity) |_| {
        if (table[index].state != 1) { table[index] = .{ .state = 1, .key = key, .value = value }; return; }
        if (table[index].key == key) { table[index].value = value; return; }
        index = (index + 1) % capacity;
    }
}

fn resize(table: *[MAX_CAPACITY]Entry, capacity: *usize, next: usize, size: *usize) void {
    const old = table.*;
    const old_capacity = capacity.*;
    for (0..next) |i| table[i] = .{};
    capacity.* = next;
    size.* = 0;
    for (0..old_capacity) |i| if (old[i].state == 1) {
        place(table, next, old[i].key, old[i].value);
        size.* += 1;
    };
}

const Find = struct { found: usize, tombstone: usize, tomb_before: bool };
fn find(table: *const [MAX_CAPACITY]Entry, capacity: usize, key: i64) Find {
    var index: usize = @intCast(@mod(key, @as(i64, @intCast(capacity))));
    var tombstone = capacity;
    for (0..capacity) |_| {
        if (table[index].state == 0) return .{ .found = capacity, .tombstone = tombstone, .tomb_before = false };
        if (table[index].state == 2) {
            if (tombstone == capacity) tombstone = index;
        } else if (table[index].key == key) {
            return .{ .found = index, .tombstone = tombstone, .tomb_before = tombstone != capacity };
        }
        index = (index + 1) % capacity;
    }
    return .{ .found = capacity, .tombstone = tombstone, .tomb_before = false };
}

export fn hash_map_open_addressing(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 1 + 3 * MAX_OPERATIONS) return -1;
    const q = input[0];
    if (q < 0 or q > @as(i64, @intCast(MAX_OPERATIONS)) or length != 1 + 3 * @as(usize, @intCast(q))) return -1;
    var table: [MAX_CAPACITY]Entry = @splat(.{});
    var capacity: usize = 8;
    var size: usize = 0;
    var query_sum: i64 = 0;
    var query_index: i64 = 0;

    for (0..@intCast(q)) |opi| {
        const opcode = input[1 + 3 * opi];
        const key = input[2 + 3 * opi];
        const value = input[3 + 3 * opi];
        if (opcode == 0) {
            if (key < 0 or key > 1_000_000 or value < -1_000_000 or value > 1_000_000) return -1;
            const before = find(&table, capacity, key);
            if (before.found == capacity and size >= MAX_KEYS) return -1;
            if (size >= capacity * 3 / 4) {
                if (capacity * 2 > MAX_CAPACITY) return -1;
                resize(&table, &capacity, capacity * 2, &size);
            }
            const result = find(&table, capacity, key);
            if (result.found != capacity) {
                if (result.tomb_before) return -1;
                table[result.found].value = value;
            } else {
                var index: usize = @intCast(@mod(key, @as(i64, @intCast(capacity))));
                var target = result.tombstone;
                for (0..capacity) |_| {
                    if (table[index].state == 0) { if (target == capacity) target = index; break; }
                    index = (index + 1) % capacity;
                }
                if (target == capacity) return -1;
                table[target] = .{ .state = 1, .key = key, .value = value };
                size += 1;
            }
        } else if (opcode == 1 or opcode == 2 or opcode == 3) {
            if (key < 0 or key > 1_000_000 or value != 0) return -1;
            const result = find(&table, capacity, key);
            if ((opcode == 1 or opcode == 2) and result.found == capacity) return -1;
            if (opcode == 1) {
                query_index += 1;
                query_sum += query_index * (table[result.found].value + VALUE_OFFSET);
            } else if (opcode == 2) {
                table[result.found].state = 2;
                size -= 1;
                if (capacity > 8 and size < capacity * 3 / 8) {
                    const next_capacity = capacity / 2;
                    resize(&table, &capacity, next_capacity, &size);
                }
            } else {
                query_index += 1;
                query_sum += query_index * (if (result.found != capacity) @as(i64, 1) else 0) + query_index * VALUE_OFFSET;
            }
        } else if (opcode == 4) {
            if (key != 0 or value != 0) return -1;
            query_index += 1;
            query_sum += query_index * (@as(i64, @intCast(size)) + VALUE_OFFSET);
        } else return -1;
    }

    var keys: [MAX_KEYS]i64 = @splat(0);
    var vals: [MAX_KEYS]i64 = @splat(0);
    var count: usize = 0;
    for (0..capacity) |i| if (table[i].state == 1) {
        var at = count;
        count += 1;
        while (at > 0 and keys[at - 1] > table[i].key) {
            keys[at] = keys[at - 1]; vals[at] = vals[at - 1]; at -= 1;
        }
        keys[at] = table[i].key; vals[at] = table[i].value;
    };
    var final_state: i64 = 0;
    for (0..count) |i| final_state += (@as(i64, @intCast(i)) + 1) * (keys[i] + 1) * (vals[i] + VALUE_OFFSET);
    return query_sum + final_state + @as(i64, @intCast(size));
}
