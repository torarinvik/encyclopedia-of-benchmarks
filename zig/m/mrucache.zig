const MAX_OPERATIONS: usize = 128;
const MAX_CAPACITY: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS + 1;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashResponses(responses: []const i32) i64 {
    var hash = FNV_OFFSET;
    const response_count: u16 = @intCast(responses.len);
    for (0..2) |byte_index| {
        const byte: u8 = @truncate(response_count >> @intCast(byte_index * 8));
        hash = (hash ^ byte) *% FNV_PRIME;
    }
    for (responses) |response| {
        const bits: u32 = @bitCast(response);
        for (0..4) |byte_index| {
            const byte: u8 = @truncate(bits >> @intCast(byte_index * 8));
            hash = (hash ^ byte) *% FNV_PRIME;
        }
    }
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const capacity64 = input[0];
    const operation_count64 = input[1];
    if (capacity64 < 1 or capacity64 > @as(i64, MAX_CAPACITY)
        or operation_count64 < 0 or operation_count64 > @as(i64, MAX_OPERATIONS)
        or input.len != 2 + 3 * @as(usize, @intCast(operation_count64))) return null;
    const capacity: usize = @intCast(capacity64);
    const operation_count: usize = @intCast(operation_count64);
    var keys: [MAX_CAPACITY]i32 = [_]i32{0} ** MAX_CAPACITY;
    var values: [MAX_CAPACITY]i32 = [_]i32{0} ** MAX_CAPACITY;
    var responses: [MAX_OPERATIONS]i32 = [_]i32{0} ** MAX_OPERATIONS;
    var cache_count: usize = 0;
    var response_count: usize = 0;

    for (0..operation_count) |step| {
        const operation = input[2 + 3 * step];
        const key64 = input[3 + 3 * step];
        const value64 = input[4 + 3 * step];
        if (operation < 0 or operation > 1 or key64 < -2147483648 or key64 > 2147483647
            or value64 < -2147483648 or value64 > 2147483647) return null;
        const key: i32 = @intCast(key64);
        const value: i32 = @intCast(value64);
        var position: usize = 0;
        while (position < cache_count and keys[position] != key) position += 1;

        if (operation == 0) {
            if (value < 0 or value > 1_000_000) return null;
            if (position < cache_count) {
                for (position..(cache_count - 1)) |index| {
                    keys[index] = keys[index + 1];
                    values[index] = values[index + 1];
                }
                keys[cache_count - 1] = key;
                values[cache_count - 1] = value;
            } else {
                if (cache_count == capacity) cache_count -= 1;
                keys[cache_count] = key;
                values[cache_count] = value;
                cache_count += 1;
            }
        } else if (position == cache_count) {
            responses[response_count] = -1;
            response_count += 1;
        } else {
            const response = values[position];
            for (position..(cache_count - 1)) |index| {
                keys[index] = keys[index + 1];
                values[index] = values[index + 1];
            }
            keys[cache_count - 1] = key;
            values[cache_count - 1] = response;
            responses[response_count] = response;
            response_count += 1;
        }
    }
    return hashResponses(responses[0..response_count]);
}

export fn mrucache(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
