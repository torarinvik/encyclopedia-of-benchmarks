const MAX_CAPACITY: usize = 64;
const MAX_COUNT: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 258;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 259;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn sliding_window_aggregator(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_CAPACITY)) or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_COUNT))) return INVALID_RESULT;
    const capacity: usize = @intCast(input[0]);
    const count: usize = @intCast(input[1]);
    if (length != count + 2 or length > MAX_VALID_INPUT_LENGTH) return INVALID_RESULT;

    var window: [MAX_CAPACITY]i64 = @splat(0);
    var head: usize = 0;
    var size: usize = 0;
    var sum: i64 = 0;
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
        if (size < capacity) {
            const position = (head + size) % capacity;
            window[position] = value;
            size += 1;
            sum += value;
        } else {
            sum -= window[head];
            window[head] = value;
            sum += value;
            head = (head + 1) % capacity;
        }
    }
    return sum;
}
