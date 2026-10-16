const MAX_IDS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 130;
const CAPACITY: usize = 1024;
const FNV_OFFSET_BASIS: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn adlerKey(id: i64) u64 {
    var a: u64 = 1;
    var b: u64 = 0;
    for ([_]u8{ 'k', 'e', 'y' }) |byte| {
        a = (a + byte) % 65521;
        b = (b + a) % 65521;
    }
    if (id >= 10) {
        a = (a + @as(u64, @intCast(@divTrunc(id, 10) + 48))) % 65521;
        b = (b + a) % 65521;
    }
    a = (a + @as(u64, @intCast(@mod(id, 10) + 48))) % 65521;
    b = (b + a) % 65521;
    return (b << 16) | a;
}

fn bucketForId(id: i64) usize {
    const hash = adlerKey(id);
    return @intCast((CAPACITY - 1) & (hash ^ (hash >> 12)));
}

fn fnvWord(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        hash ^= (bits >> @intCast(8 * byte)) & 0xff;
        hash *%= FNV_PRIME;
    }
    return hash;
}

export fn hash_set(input_pointer: ?[*]const i64, length: usize) i64 {
    const input = input_pointer orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH or input[0] < 0 or input[0] > MAX_IDS) return -1;
    const add_count: usize = @intCast(input[0]);
    const query_count_index = 1 + add_count;
    if (query_count_index >= length or input[query_count_index] < 0 or input[query_count_index] > MAX_IDS) return -1;
    const query_count: usize = @intCast(input[query_count_index]);
    if (length != 2 + add_count + query_count) return -1;

    for (0..add_count) |index| {
        const id = input[1 + index];
        if (id < 0 or id >= MAX_IDS) return -1;
    }
    for (0..query_count) |index| {
        const id = input[query_count_index + 1 + index];
        if (id < 0 or id >= MAX_IDS) return -1;
    }

    var occupied = [_]bool{false} ** CAPACITY;
    var slot_ids: [CAPACITY]i64 = undefined;
    var set_length: i64 = 0;
    for (0..add_count) |index| {
        const id = input[1 + index];
        const bucket = bucketForId(id);
        if (!occupied[bucket]) {
            occupied[bucket] = true;
            slot_ids[bucket] = id;
            set_length += 1;
        } else if (slot_ids[bucket] != id) {
            return -1;
        }
    }

    var result = fnvWord(FNV_OFFSET_BASIS, set_length);
    for (0..query_count) |index| {
        const id = input[query_count_index + 1 + index];
        const bucket = bucketForId(id);
        const contains: i64 = if (occupied[bucket] and slot_ids[bucket] == id) 1 else 0;
        result = fnvWord(result, contains);
    }
    return @intCast(result & 0x7fff_ffff_ffff_ffff);
}
