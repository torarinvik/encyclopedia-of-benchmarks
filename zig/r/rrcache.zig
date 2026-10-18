const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_OPERATIONS;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1 << 48) - 1;

fn javaNextBits(state: *u64, bits: u32) u32 {
    state.* = (state.* *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK;
    return @intCast(state.* >> @intCast(48 - bits));
}

fn javaNextInt(state: *u64, bound: u32) u32 {
    if ((bound & (bound - 1)) == 0)
        return @intCast((@as(u64, bound) * javaNextBits(state, 31)) >> 31);
    while (true) {
        const bits = javaNextBits(state, 31);
        const value = bits % bound;
        if (@as(u64, bits) - @as(u64, value) + @as(u64, bound - 1) <= 0x7fffffff) return value;
    }
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rrcache(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8 or input[2] < 0 or input[2] > MAX_OPERATIONS) return -1;
    const cache_capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[2]);
    if (length != 3 + 3 * operation_count) return -1;

    var keys: [8]i64 = [_]i64{0} ** 8;
    var values: [8]i64 = [_]i64{0} ** 8;
    var results: [MAX_OPERATIONS]i64 = [_]i64{0} ** MAX_OPERATIONS;
    var size: usize = 0;
    const seed_bits: u64 = @bitCast(input[1]);
    var random_state = (seed_bits ^ JAVA_MULTIPLIER) & JAVA_MASK;

    for (0..operation_count) |operation| {
        const offset = 3 + 3 * operation;
        const opcode = input[offset];
        const key = input[offset + 1];
        const value = input[offset + 2];
        if (opcode == 0) {
            if (key < 1 or key > 1024 or value < 100 or value > 1_000_000) return -1;
            var index: usize = 0;
            while (index < size and keys[index] != key) : (index += 1) {}
            if (index < size) {
                values[index] = value;
            } else {
                if (size == cache_capacity) {
                    const evicted: usize = javaNextInt(&random_state, @intCast(size));
                    for (evicted..size - 1) |movement| {
                        keys[movement] = keys[movement + 1];
                        values[movement] = values[movement + 1];
                    }
                    size -= 1;
                }
                keys[size] = key;
                values[size] = value;
                size += 1;
            }
            results[operation] = -2;
        } else if (opcode == 1) {
            if (key < 1 or key > 1024 or value != 0) return -1;
            var index: usize = 0;
            while (index < size and keys[index] != key) : (index += 1) {}
            results[operation] = if (index < size) values[index] else -1;
        } else if (opcode == 2) {
            if (key != 0 or value != 0) return -1;
            results[operation] = @intCast(size);
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
