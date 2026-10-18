const max_length = 5;
const max_input = 7;
const max_output = 601;

export fn permutation_unique_string(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > max_input) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > max_length or input_length != @as(usize, @intCast(values[0])) + 1) return -1;
    const length: usize = @intCast(values[0]);
    var current = [_]u8{0} ** max_length;
    for (0..length) |i| {
        if (values[i + 1] < 32 or values[i + 1] > 126) return -1;
        current[i] = @intCast(values[i + 1]);
    }
    var i: usize = 1;
    while (i < length) : (i += 1) {
        const value = current[i];
        var j = i;
        while (j > 0 and current[j - 1] > value) : (j -= 1) current[j] = current[j - 1];
        current[j] = value;
    }
    var staged = [_]u8{0} ** max_output;
    var count: usize = 0;
    while (true) {
        for (0..length) |index| staged[1 + count * length + index] = current[index];
        count += 1;
        if (length < 2) break;
        var pivot = length - 1;
        while (pivot > 0 and current[pivot - 1] >= current[pivot]) : (pivot -= 1) {}
        if (pivot == 0) break;
        var successor = length - 1;
        while (current[successor] <= current[pivot - 1]) : (successor -= 1) {}
        const temp = current[pivot - 1];
        current[pivot - 1] = current[successor];
        current[successor] = temp;
        var left = pivot;
        var right = length - 1;
        while (left < right) {
            const swap = current[left]; current[left] = current[right]; current[right] = swap;
            left += 1; right -= 1;
        }
    }
    staged[0] = @intCast(count);
    const output_size = 1 + count * length;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
