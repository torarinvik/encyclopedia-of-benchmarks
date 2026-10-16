const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_Q;
const VALUE_LIMIT: i64 = 1_000_000;
const VALUE_OFFSET: i64 = 1_000_001;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

export fn ring_buffer(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = packed orelse return -1;
    const qv = input[0];
    if (qv < 0 or qv > @as(i64, @intCast(MAX_Q)) or length != 1 + @as(usize, @intCast(qv)) * 2) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const payload = input[2 + i * 2];
        if (op == 0) { if (payload < -VALUE_LIMIT or payload > VALUE_LIMIT) return -1; }
        else if (op == 4) { if (payload < 0 or payload > VALUE_LIMIT) return -1; }
        else if (op >= 1 and op <= 3) { if (payload != 0) return -1; }
        else if (op >= 5 and op <= 9) { if (payload != 0) return -1; }
        else return -1;
    }

    var values: [8]i64 = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    var count: usize = 0;
    var hash: i64 = 0;
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const payload = input[2 + i * 2];
        var status: i64 = 0;
        var result: i64 = 0;
        if (op == 0) {
            if (count == 8) { status = 1; }
            else { values[tail] = payload; tail = (tail + 1) % 8; count += 1; }
        } else if (op == 1) {
            if (count == 0) { status = 2; }
            else { result = values[head]; head = (head + 1) % 8; count -= 1; }
        } else if (op == 2) {
            if (count == 0) { status = 2; } else { result = values[head]; }
        } else if (op == 3) {
            if (count == 0) { status = 2; } else { result = values[(tail + 7) % 8]; }
        } else if (op == 4) {
            if (payload >= @as(i64, @intCast(count))) { status = 3; }
            else { result = values[(head + @as(usize, @intCast(payload))) % 8]; }
        } else if (op == 5) {
            head = 0; tail = 0; count = 0;
        } else if (op == 6) { result = @intCast(count); }
        else if (op == 7) { result = 8 - @as(i64, @intCast(count)); }
        else if (op == 8) { result = @intFromBool(count == 0); }
        else { result = @intFromBool(count == 8); }

        hash = @mod(hash * HASH_MULTIPLIER + op, HASH_MODULUS);
        hash = @mod(hash * HASH_MULTIPLIER + status, HASH_MODULUS);
        hash = @mod(hash * HASH_MULTIPLIER + result + VALUE_OFFSET, HASH_MODULUS);
        hash = @mod(hash * HASH_MULTIPLIER + @as(i64, @intCast(count)), HASH_MODULUS);
        for (0..count) |j| {
            const position = (head + j) % 8;
            hash = @mod(hash * HASH_MULTIPLIER + values[position] + VALUE_OFFSET, HASH_MODULUS);
        }
    }
    return hash;
}
