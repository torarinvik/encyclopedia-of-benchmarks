const TABLE_CAPACITY: usize = 16;
const MAX_ACTIVE_ENTRIES: usize = 14;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_OPERATIONS;
const MAX_PROBE_DISTANCE: u32 = 64;
const GOLDEN_RATIO: u64 = 0x9E3779B97F4A7C15;

const Entry = struct { key: u32 = 0, value: u32 = 0, psl: u32 = 0, occupied: bool = false };
const RobinHoodMap = struct { entries: [TABLE_CAPACITY]Entry, count: usize };

fn hashKey(key: u32) usize {
    const product = @as(u64, key) *% GOLDEN_RATIO;
    return @intCast((product >> 32) & (TABLE_CAPACITY - 1));
}

fn mapPut(map: *RobinHoodMap, key: u32, value: u32) bool {
    if ((map.count * 100) / TABLE_CAPACITY >= 90) return false;
    var entry = Entry{ .key = key, .value = value, .psl = 0, .occupied = true };
    var index = hashKey(key);
    var probes: u32 = 0;
    while (probes < MAX_PROBE_DISTANCE) : (probes += 1) {
        if (!map.entries[index].occupied) {
            map.entries[index] = entry;
            map.count += 1;
            return true;
        }
        if (map.entries[index].key == key) {
            map.entries[index].value = value;
            return true;
        }
        if (entry.psl > map.entries[index].psl) {
            const temp = map.entries[index];
            map.entries[index] = entry;
            entry = temp;
        }
        entry.psl += 1;
        index = (index + 1) & (TABLE_CAPACITY - 1);
    }
    return false;
}

fn mapGet(map: *const RobinHoodMap, key: u32) ?u32 {
    var index = hashKey(key);
    var psl: u32 = 0;
    while (psl < MAX_PROBE_DISTANCE) : (psl += 1) {
        const resident = map.entries[index];
        if (!resident.occupied) return null;
        if (resident.key == key) return resident.value;
        if (psl > resident.psl) return null;
        index = (index + 1) & (TABLE_CAPACITY - 1);
    }
    return null;
}

fn mapBackshift(map: *RobinHoodMap, start: usize) void {
    var index = start;
    for (0..TABLE_CAPACITY) |_| {
        const next = (index + 1) & (TABLE_CAPACITY - 1);
        if (!map.entries[next].occupied or map.entries[next].psl == 0) {
            map.entries[index].occupied = false;
            map.entries[index].psl = 0;
            return;
        }
        map.entries[index] = map.entries[next];
        map.entries[index].psl -= 1;
        index = next;
    }
}

fn mapRemove(map: *RobinHoodMap, key: u32) bool {
    var index = hashKey(key);
    var psl: u32 = 0;
    while (psl < MAX_PROBE_DISTANCE) : (psl += 1) {
        const resident = map.entries[index];
        if (!resident.occupied) return false;
        if (resident.key == key) {
            mapBackshift(map, index);
            map.count -= 1;
            return true;
        }
        if (psl > resident.psl) return false;
        index = (index + 1) & (TABLE_CAPACITY - 1);
    }
    return false;
}

fn mapClear(map: *RobinHoodMap) void {
    for (&map.entries) |*entry| { entry.occupied = false; entry.psl = 0; }
    map.count = 0;
}

fn mapMaxPsl(map: *const RobinHoodMap) u32 {
    var maximum: u32 = 0;
    for (map.entries) |entry| if (entry.occupied and entry.psl > maximum) { maximum = entry.psl; };
    return maximum;
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn robin_hood_hash(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + 3 * operation_count) return -1;

    var map = RobinHoodMap{ .entries = [_]Entry{Entry{}} ** TABLE_CAPACITY, .count = 0 };
    var results: [MAX_OPERATIONS]i64 = [_]i64{0} ** MAX_OPERATIONS;
    for (0..operation_count) |operation| {
        const offset = 1 + 3 * operation;
        const opcode = input[offset];
        const raw_key = input[offset + 1];
        const raw_value = input[offset + 2];
        if (opcode == 0) {
            if (raw_key < 0 or raw_key > 4294967295 or raw_value < 100 or raw_value > 1_000_000) return -1;
            if (!mapPut(&map, @intCast(raw_key), @intCast(raw_value)) or map.count > MAX_ACTIVE_ENTRIES) return -1;
            results[operation] = -2;
        } else if (opcode == 1 or opcode == 2) {
            if (raw_key < 0 or raw_key > 4294967295 or raw_value != 0) return -1;
            const key: u32 = @intCast(raw_key);
            if (opcode == 1) {
                results[operation] = if (mapGet(&map, key)) |value| value else -1;
            } else {
                results[operation] = if (mapRemove(&map, key)) 1 else 0;
            }
        } else if (opcode >= 3 and opcode <= 7) {
            if (raw_key != 0 or raw_value != 0) return -1;
            if (opcode == 3) {
                results[operation] = @intCast(map.count);
            } else if (opcode == 4) {
                results[operation] = @intCast((map.count * 100) / TABLE_CAPACITY);
            } else if (opcode == 5) {
                results[operation] = @intCast(mapMaxPsl(&map));
            } else if (opcode == 6) {
                mapClear(&map);
                results[operation] = -3;
            } else {
                results[operation] = if (map.count == 0) 1 else 0;
            }
        } else return -1;
    }

    const output_bytes = operation_count * 8;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..operation_count) |operation| putI64Le(&staged, operation * 8, results[operation]);
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
