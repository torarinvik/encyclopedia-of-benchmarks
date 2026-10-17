const MAX_LENGTH: usize = 6;

fn emitRow(values: *const [MAX_LENGTH]i32, length: usize, output: [*]u8, offset: *usize) void {
    for (0..length) |index| {
        const bits: u32 = @bitCast(values[index]);
        for (0..4) |byte| {
            output[offset.*] = @truncate(bits >> @intCast(byte * 8));
            offset.* += 1;
        }
    }
}

export fn steinhaus_johnson_trotter(input: [*c]const i32, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_LENGTH) return -1;
    var permutations: usize = 1;
    var factor: usize = 2;
    while (factor <= length) : (factor += 1) permutations *= factor;
    const required = 4 * length * permutations;
    if (output == null or output_capacity < required) return -2;

    var values: [MAX_LENGTH]i32 = undefined;
    var inversion: [MAX_LENGTH]usize = [_]usize{0} ** MAX_LENGTH;
    for (0..length) |index| values[index] = input[index];
    var offset: usize = 0;
    emitRow(&values, length, output, &offset);

    var index: usize = 1;
    while (index < length) {
        if (inversion[index] < index) {
            const swap_index: usize = if (index % 2 == 0) 0 else inversion[index];
            const temporary = values[swap_index];
            values[swap_index] = values[index];
            values[index] = temporary;
            emitRow(&values, length, output, &offset);
            inversion[index] += 1;
            index = 1;
        } else {
            inversion[index] = 0;
            index += 1;
        }
    }
    return @intCast(required);
}
