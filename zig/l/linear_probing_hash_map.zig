const MAX_CAPACITY: usize = 128;
const MAX_WORDS: usize = 320;

const HashMap = struct {
    keys: [MAX_CAPACITY]i32,
    values: [MAX_CAPACITY]i32,
    occupied: [MAX_CAPACITY]bool,
    capacity: usize,
    size: usize,
};

fn hash_index(key: i32, capacity: usize) usize {
    const bits: u32 = @bitCast(key);
    return @intCast((bits & 0x7fff_ffff) % @as(u32, @intCast(capacity)));
}

fn resize_map(map: *HashMap, new_capacity: usize) void {
    const old_keys = map.keys;
    const old_values = map.values;
    const old_occupied = map.occupied;
    const old_capacity = map.capacity;
    map.capacity = new_capacity;
    for (0..new_capacity) |i| map.occupied[i] = false;
    for (0..old_capacity) |i| {
        if (!old_occupied[i]) continue;
        var index = hash_index(old_keys[i], new_capacity);
        while (map.occupied[index]) index = (index + 1) % new_capacity;
        map.keys[index] = old_keys[i];
        map.values[index] = old_values[i];
        map.occupied[index] = true;
    }
}

fn find_slot(map: *const HashMap, key: i32) usize {
    var index = hash_index(key, map.capacity);
    for (0..map.capacity) |_| {
        if (!map.occupied[index]) return map.capacity;
        if (map.keys[index] == key) return index;
        index = (index + 1) % map.capacity;
    }
    return map.capacity;
}

fn put(map: *HashMap, key: i32, value: i32) void {
    if (map.size > map.capacity / 2) resize_map(map, map.capacity * 2);
    var index = hash_index(key, map.capacity);
    while (map.occupied[index]) {
        if (map.keys[index] == key) { map.values[index] = value; return; }
        index = (index + 1) % map.capacity;
    }
    map.keys[index] = key;
    map.values[index] = value;
    map.occupied[index] = true;
    map.size += 1;
}

fn delete_key(map: *HashMap, key: i32) bool {
    var index = find_slot(map, key);
    if (index == map.capacity) return false;
    map.occupied[index] = false;
    map.values[index] = 0;
    index = (index + 1) % map.capacity;
    while (map.occupied[index]) {
        const k = map.keys[index];
        const v = map.values[index];
        map.occupied[index] = false;
        map.values[index] = 0;
        map.size -= 1;
        put(map, k, v);
        index = (index + 1) % map.capacity;
    }
    map.size -= 1;
    if (map.size > 0 and map.size <= map.capacity / 8) resize_map(map, map.capacity / 2);
    return true;
}

fn append(words: *[MAX_WORDS]i64, count: *usize, value: i64) void {
    words[count.*] = value;
    count.* += 1;
}

export fn linear_probing_hash_map(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 98) return -1;
    const input = input_opt.?;
    if (input[0] < 4 or input[0] > 16 or input[1] < 0 or input[1] > 32) return -1;
    const op_count: usize = @intCast(input[1]);
    if (length > 2 + 3 * op_count) return -1;
    var map = HashMap{
        .keys = [_]i32{0} ** MAX_CAPACITY,
        .values = [_]i32{0} ** MAX_CAPACITY,
        .occupied = [_]bool{false} ** MAX_CAPACITY,
        .capacity = @intCast(input[0]),
        .size = 0,
    };
    var words: [MAX_WORDS]i64 = undefined;
    var word_count: usize = 0;
    var pos: usize = 2;
    for (0..op_count) |_| {
        if (pos >= length) return -1;
        const op = input[pos];
        pos += 1;
        if (op == 0) {
            if (pos + 1 >= length) return -1;
            const key = input[pos];
            const value = input[pos + 1];
            pos += 2;
            if (key < -2147483648 or key > 2147483647 or value < -2147483648 or value > 2147483647) return -1;
            put(&map, @intCast(key), @intCast(value));
            append(&words, &word_count, 0);
            append(&words, &word_count, 1);
        } else if (op >= 1 and op <= 3) {
            if (pos >= length) return -1;
            const key = input[pos];
            pos += 1;
            if (key < -2147483648 or key > 2147483647) return -1;
            const k: i32 = @intCast(key);
            const index = find_slot(&map, k);
            if (op == 1) {
                append(&words, &word_count, 1);
                if (index == map.capacity) {
                    append(&words, &word_count, 1);
                    append(&words, &word_count, 0);
                } else {
                    append(&words, &word_count, 0);
                    append(&words, &word_count, map.values[index]);
                }
            } else if (op == 2) {
                append(&words, &word_count, 2);
                append(&words, &word_count, if (delete_key(&map, k)) 1 else 0);
            } else {
                append(&words, &word_count, 3);
                append(&words, &word_count, if (index != map.capacity) 1 else 0);
            }
        } else if (op == 4) {
            append(&words, &word_count, 4);
            append(&words, &word_count, @intCast(map.size));
        } else if (op == 5) {
            var sorted: [32]i32 = undefined;
            var count: usize = 0;
            for (0..map.capacity) |i| {
                if (map.occupied[i]) { sorted[count] = map.keys[i]; count += 1; }
            }
            for (1..count) |i| {
                const value = sorted[i];
                var j = i;
                while (j > 0 and sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; j -= 1; }
                sorted[j] = value;
            }
            append(&words, &word_count, 5);
            append(&words, &word_count, @intCast(count));
            for (0..count) |i| append(&words, &word_count, sorted[i]);
        } else return -1;
    }
    if (pos != length or word_count > MAX_WORDS) return -1;
    const bytes = word_count * 8;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..word_count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |b| output[8 * i + b] = @truncate(bits >> @intCast(8 * b));
    }
    return @intCast(bytes);
}
