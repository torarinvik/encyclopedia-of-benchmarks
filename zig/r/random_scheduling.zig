const MAX_TASK_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 35;
const MAX_OUTPUT_BYTES: usize = 256;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = 0xFFFFFFFFFFFF;

const JavaRandom = struct {
    state: u64,

    fn nextBits(self: *JavaRandom, bits: u6) u32 {
        self.state = (self.state *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK;
        return @intCast(self.state >> (48 - bits));
    }

    fn nextInt(self: *JavaRandom, bound: u32) u32 {
        if (bound & (bound - 1) == 0) {
            return @intCast((@as(u64, bound) * self.nextBits(31)) >> 31);
        }
        while (true) {
            const bits = self.nextBits(31);
            const value = bits % bound;
            if (@as(u64, bits) - value + (bound - 1) <= 0x7fffffff) return value;
        }
    }
};

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn random_scheduling(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    if (values[1] < 0 or values[1] > MAX_TASK_COUNT) return -1;
    const count: usize = @intCast(values[1]);
    if (input_length != count + 2) return -1;

    var tasks = [_]i64{0} ** MAX_TASK_COUNT;
    for (0..count) |index| {
        const task = values[index + 2];
        if (task < std.math.minInt(i32) or task > std.math.maxInt(i32)) return -1;
        tasks[index] = task;
    }
    var random = JavaRandom{ .state = (@as(u64, @bitCast(values[0])) ^ JAVA_MULTIPLIER) & JAVA_MASK };
    var size = count;
    while (size > 1) : (size -= 1) {
        const selected: usize = @intCast(random.nextInt(@intCast(size)));
        const saved = tasks[size - 1];
        tasks[size - 1] = tasks[selected];
        tasks[selected] = saved;
    }

    const output_bytes = count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const output_ptr = output orelse return -2;
    if (capacity < output_bytes) return -2;
    const output_slice = output_ptr[0..output_bytes];
    for (0..count) |index| writeI64Le(output_slice, index * 8, tasks[index]);
    return @intCast(output_bytes);
}
