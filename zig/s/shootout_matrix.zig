const MATRIX_SIZE: usize = 10;
const CELL_COUNT: usize = MATRIX_SIZE * MATRIX_SIZE;
const MAX_ITERATIONS: i64 = 4096;
const MAX_OUTPUT_BYTES: usize = 23;

fn appendInteger(value: i32, buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize) void {
    var remaining = value;
    var reversed: [10]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + @mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[used.*] = reversed[count];
        used.* += 1;
    }
}

export fn shootout_matrix(iteration_count: i64, output_opt: ?[*]u8,
    output_capacity: usize) i64 {
    if (iteration_count < 0 or iteration_count > MAX_ITERATIONS) return -1;

    var left: [CELL_COUNT]i32 = undefined;
    var right: [CELL_COUNT]i32 = undefined;
    var product: [CELL_COUNT]i32 = undefined;
    for (0..CELL_COUNT) |index| {
        left[index] = @intCast(index + 1);
        right[index] = @intCast(index + 1);
        product[index] = @intCast(index + 1);
    }

    var iteration: i64 = 0;
    while (iteration < iteration_count) : (iteration += 1) {
        for (0..MATRIX_SIZE) |row| {
            for (0..MATRIX_SIZE) |column| {
                var value: i32 = 0;
                for (0..MATRIX_SIZE) |inner| {
                    value += left[row * MATRIX_SIZE + inner] * right[inner * MATRIX_SIZE + column];
                }
                product[row * MATRIX_SIZE + column] = value;
            }
        }
    }

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    appendInteger(product[0], &staged, &used);
    staged[used] = ' ';
    used += 1;
    appendInteger(product[23], &staged, &used);
    staged[used] = ' ';
    used += 1;
    appendInteger(product[32], &staged, &used);
    staged[used] = ' ';
    used += 1;
    appendInteger(product[44], &staged, &used);
    staged[used] = '\n';
    used += 1;

    if (output_opt == null or output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
