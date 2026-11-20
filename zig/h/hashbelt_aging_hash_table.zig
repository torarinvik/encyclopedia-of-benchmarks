const GENERATIONS: usize = 4;
const BUCKETS: usize = 8;
const MAX_KEYS: usize = 32;
const MAX_OPS: usize = 64;
const MAX_WORDS: usize = 1 + 3 * MAX_OPS + 1;
const MISS: i64 = -2147483648;

fn findInTable(heads: []const i16, keys: []const i16, links: []const i16,
    table: usize, key: usize) isize {
    var node: isize = heads[table * BUCKETS + key % BUCKETS];
    while (node >= 0) {
        const record = table * MAX_KEYS + @as(usize, @intCast(node));
        if (keys[record] == @as(i16, @intCast(key))) return node;
        node = links[record];
    }
    return -1;
}

fn findKey(heads: []const i16, keys: []const i16, links: []const i16,
    newest: usize, key: usize) isize {
    for (0..GENERATIONS) |age| {
        const table = (newest + age) % GENERATIONS;
        const node = findInTable(heads, keys, links, table, key);
        if (node >= 0) return @as(isize, @intCast(table * MAX_KEYS)) + node;
    }
    return -1;
}

fn put(heads: []i16, keys: []i16, values: []i16, links: []i16,
    used: []i16, newest: usize, key: usize, value: i16) void {
    const existing = findInTable(heads, keys, links, newest, key);
    if (existing >= 0) {
        values[newest * MAX_KEYS + @as(usize, @intCast(existing))] = value;
        return;
    }
    var node: usize = 0;
    while (node < MAX_KEYS and keys[newest * MAX_KEYS + node] >= 0) : (node += 1) {}
    if (node >= MAX_KEYS) return;
    used[newest] += 1;
    const bucket = key % BUCKETS;
    const record = newest * MAX_KEYS + node;
    keys[record] = @intCast(key);
    values[record] = value;
    links[record] = heads[newest * BUCKETS + bucket];
    heads[newest * BUCKETS + bucket] = @intCast(node);
}

fn remove(heads: []i16, keys: []i16, values: []i16, links: []i16,
    used: []i16, table: usize, key: usize, target: usize) void {
    const bucket = key % BUCKETS;
    var previous: isize = -1;
    var node: isize = heads[table * BUCKETS + bucket];
    while (node >= 0 and @as(usize, @intCast(node)) != target) {
        previous = node;
        node = links[table * MAX_KEYS + @as(usize, @intCast(node))];
    }
    if (node < 0) return;
    const index: usize = @intCast(node);
    if (previous < 0) heads[table * BUCKETS + bucket] = links[table * MAX_KEYS + index]
    else links[table * MAX_KEYS + @as(usize, @intCast(previous))] = links[table * MAX_KEYS + index];
    keys[table * MAX_KEYS + index] = -1;
    values[table * MAX_KEYS + index] = 0;
    links[table * MAX_KEYS + index] = -1;
    used[table] -= 1;
}

fn writeI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn hashbelt_aging_hash_table(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_WORDS) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, MAX_OPS)) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 3 * count) return -1;
    for (0..count) |op| {
        const opcode = input[1 + 3 * op];
        const key = input[2 + 3 * op];
        const argument = input[3 + 3 * op];
        if (opcode == 0) {
            if (key < 0 or key >= @as(i64, MAX_KEYS) or argument < -1000 or argument > 1000) return -1;
        } else if (opcode == 1) {
            if (key < 0 or key >= @as(i64, MAX_KEYS) or argument != 0) return -1;
        } else if (opcode == 2) {
            if (key != 0 or argument != 0) return -1;
        } else return -1;
    }
    const required = count * 8;
    if (output == null or capacity < required) return -2;

    var heads: [GENERATIONS * BUCKETS]i16 = @splat(-1);
    var keys: [GENERATIONS * MAX_KEYS]i16 = @splat(-1);
    var values: [GENERATIONS * MAX_KEYS]i16 = @splat(0);
    var links: [GENERATIONS * MAX_KEYS]i16 = @splat(0);
    var used: [GENERATIONS]i16 = @splat(0);
    var trace: [MAX_OPS]i64 = @splat(0);
    var newest: usize = 0;
    for (0..count) |op| {
        const opcode: usize = @intCast(input[1 + 3 * op]);
        const key: usize = @intCast(input[2 + 3 * op]);
        const argument: i16 = @intCast(input[3 + 3 * op]);
        if (opcode == 0) {
            const found = findKey(heads[0..], keys[0..], links[0..], newest, key);
            trace[op] = if (found < 0) 1 else 0;
            if (found >= 0) {
                const table = @as(usize, @intCast(found)) / MAX_KEYS;
                const node = @as(usize, @intCast(found)) % MAX_KEYS;
                if (table != newest) remove(heads[0..], keys[0..], values[0..], links[0..], used[0..], table, key, node);
            }
            put(heads[0..], keys[0..], values[0..], links[0..], used[0..], newest, key, argument);
        } else if (opcode == 1) {
            const found = findKey(heads[0..], keys[0..], links[0..], newest, key);
            if (found < 0) {
                trace[op] = MISS;
            } else {
                const table = @as(usize, @intCast(found)) / MAX_KEYS;
                const node = @as(usize, @intCast(found)) % MAX_KEYS;
                const value = values[table * MAX_KEYS + node];
                trace[op] = @as(i64, value);
                if (table != newest) {
                    remove(heads[0..], keys[0..], values[0..], links[0..], used[0..], table, key, node);
                    put(heads[0..], keys[0..], values[0..], links[0..], used[0..], newest, key, value);
                }
            }
        } else {
            const oldest = (newest + GENERATIONS - 1) % GENERATIONS;
            trace[op] = @as(i64, used[oldest]);
            for (0..BUCKETS) |bucket| heads[oldest * BUCKETS + bucket] = -1;
            for (0..MAX_KEYS) |slot| keys[oldest * MAX_KEYS + slot] = -1;
            used[oldest] = 0;
            newest = oldest;
        }
    }
    for (0..count) |op| writeI64Le(output, op, trace[op]);
    return @intCast(required);
}
