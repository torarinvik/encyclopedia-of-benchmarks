/// Minimum updates needed to equalize a vector with a fixed step size.
export fn matrix_equalization(input: ?[*]const i64, length: usize) i64 {
    const max_vector_length: usize = 64;
    const max_input_length: usize = max_vector_length + 2;
    if (length < 2 or length > max_input_length) return -1;
    if (input == null) return -1;
    const values = input.?;
    const vector_length = length - 1;
    if (vector_length > max_vector_length or values[0] < 1 or
        values[0] > @as(i64, @intCast(vector_length))) return -1;
    const step_size: usize = @intCast(values[0]);
    var minimum_updates = vector_length;

    for (0..vector_length) |target_index| {
        var seen = false;
        for (0..target_index) |previous| {
            if (values[previous + 1] == values[target_index + 1]) {
                seen = true;
                break;
            }
        }
        if (seen) continue;

        var updates: usize = 0;
        var index: usize = 0;
        while (index < vector_length) {
            if (values[index + 1] == values[target_index + 1]) {
                index += 1;
            } else {
                updates += 1;
                index += step_size;
            }
        }
        if (updates < minimum_updates) minimum_updates = updates;
    }
    return @intCast(minimum_updates);
}
