const MAX_INPUT_LENGTH: usize = 259;
const MAX_ARITY: usize = 4;
const MAX_CALLS: usize = 64;
const MAX_OUTPUT_BYTES: usize = 520;

fn putI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        const shift: u6 = @intCast(byte_index * 8);
        output[offset + byte_index] = @truncate(bits >> shift);
    }
}

export fn memoize(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_ARITY or input[1] < 0 or input[1] > MAX_CALLS) return -1;
    const arity: usize = @intCast(input[0]);
    const call_count: usize = @intCast(input[1]);
    if (input_length != 2 + arity * call_count) return -1;
    for (0..arity * call_count) |index| {
        const value = input[2 + index];
        if (value < -100 or value > 100) return -1;
    }

    var keys = [_][MAX_ARITY]i64{[_]i64{0} ** MAX_ARITY} ** MAX_CALLS;
    var key_results = [_]i64{0} ** MAX_CALLS;
    var key_count: usize = 0;
    var results = [_]i64{0} ** (MAX_CALLS + 1);
    for (0..call_count) |call_index| {
        const start = 2 + call_index * arity;
        var key = [_]i64{0} ** MAX_ARITY;
        var encoded: i64 = 0;
        for (0..arity) |argument_index| {
            const value = input[start + argument_index];
            key[argument_index] = value;
            encoded = encoded * 201 + value + 100;
        }
        var found: ?usize = null;
        for (0..key_count) |previous| {
            var equal = true;
            for (0..arity) |argument_index| {
                if (keys[previous][argument_index] != key[argument_index]) equal = false;
            }
            if (equal) { found = previous; break; }
        }
        if (found) |previous| {
            results[call_index] = key_results[previous];
        } else {
            keys[key_count] = key;
            key_results[key_count] = encoded;
            key_count += 1;
            results[call_index] = encoded;
        }
    }
    results[call_count] = @intCast(key_count);

    const output_bytes = 8 * (call_count + 1);
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..call_count + 1) |index| putI64Le(&staged, index * 8, results[index]);
    if (output == null or capacity < output_bytes) return -2;
    @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
