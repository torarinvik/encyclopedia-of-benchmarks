const MAX_OPERATIONS: usize = 256;
const MAX_QUEUE_LENGTH: usize = 64;
const MAX_VALID_INPUT_LENGTH: usize = 513;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 514;
const FNV_OFFSET: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;

fn hashByte(hash_arg: u64, byte: u8) u64 {
    return (hash_arg ^ @as(u64, byte)) *% FNV_PRIME;
}

fn hashU16(hash_arg: u64, value: u16) u64 {
    var hash = hash_arg;
    for (0..2) |byte| hash = hashByte(hash, @truncate(value >> @intCast(8 * byte)));
    return hash;
}

fn hashI32(hash_arg: u64, value: i32) u64 {
    var hash = hash_arg;
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| hash = hashByte(hash, @truncate(bits >> @intCast(8 * byte)));
    return hash;
}

fn hashI64(hash_arg: u64, value: i64) u64 {
    var hash = hash_arg;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| hash = hashByte(hash, @truncate(bits >> @intCast(8 * byte)));
    return hash;
}

export fn clojure_persistent_list_queue(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + 2 * operation_count or length > MAX_VALID_INPUT_LENGTH) return -1;

    var newest_first: [MAX_QUEUE_LENGTH]i32 = @splat(0);
    var queue_size: usize = 0;
    var results: [MAX_OPERATIONS]i64 = @splat(0);
    var opcodes: [MAX_OPERATIONS]u8 = @splat(0);
    for (0..operation_count) |operation| {
        const offset = 1 + 2 * operation;
        const opcode_value = input[offset];
        const argument = input[offset + 1];
        if (opcode_value < 0 or opcode_value > 3) return -1;
        const opcode: u8 = @intCast(opcode_value);
        opcodes[operation] = opcode;
        if (opcode == 0) {
            if (argument < -2147483648 or argument > 2147483647 or queue_size >= MAX_QUEUE_LENGTH) return -1;
            var index = queue_size;
            while (index > 0) {
                newest_first[index] = newest_first[index - 1];
                index -= 1;
            }
            newest_first[0] = @intCast(argument);
            queue_size += 1;
            results[operation] = @intCast(queue_size);
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            if (queue_size > 0) queue_size -= 1;
            results[operation] = @intCast(queue_size);
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            results[operation] = if (queue_size == 0) -9223372036854775807 - 1 else newest_first[queue_size - 1];
        } else {
            if (argument != 0) return -1;
            results[operation] = if (queue_size == 0) 1 else 0;
        }
    }

    var hash: u64 = FNV_OFFSET;
    hash = hashU16(hash, @intCast(operation_count));
    for (0..operation_count) |operation| {
        hash = hashByte(hash, opcodes[operation]);
        hash = hashI64(hash, results[operation]);
    }
    hash = hashU16(hash, @intCast(queue_size));
    var index = queue_size;
    while (index > 0) {
        index -= 1;
        hash = hashI32(hash, newest_first[index]);
    }
    return @intCast(hash & 0x7fffffffffffffff);
}
