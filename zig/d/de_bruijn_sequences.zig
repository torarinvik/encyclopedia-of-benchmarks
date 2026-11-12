const MAX_ORDER: usize = 16;
const MAX_CYCLE_LENGTH: usize = 10_000;

fn fkmGenerate(position: usize, period: usize, order: usize, alphabet: usize,
    work: *[MAX_ORDER + 1]u8, output: [*]u8, emitted: *usize) void {
    if (position > order) {
        if (order % period == 0) {
            for (1..period + 1) |index| {
                output[emitted.*] = '0' + work[index];
                emitted.* += 1;
            }
        }
        return;
    }
    work[position] = work[position - period];
    fkmGenerate(position + 1, period, order, alphabet, work, output, emitted);
    var symbol = @as(usize, work[position - period]) + 1;
    while (symbol < alphabet) : (symbol += 1) {
        work[position] = @intCast(symbol);
        fkmGenerate(position + 1, position, order, alphabet, work, output, emitted);
    }
}

export fn de_bruijn_sequences(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..2];
    if (values[0] < 2 or values[0] > 10 or values[1] < 1 or values[1] > MAX_ORDER) return -1;
    const alphabet: usize = @intCast(values[0]);
    const order: usize = @intCast(values[1]);
    var cycle_length: usize = 1;
    for (0..order) |_| {
        if (cycle_length > MAX_CYCLE_LENGTH / alphabet) return -1;
        cycle_length *= alphabet;
    }
    const output_length = cycle_length + order - 1;
    if (output == null or output_capacity < output_length) return -2;

    var work: [MAX_ORDER + 1]u8 = @splat(0);
    var emitted: usize = 0;
    const bytes = output.?[0..output_length];
    fkmGenerate(1, 1, order, alphabet, &work, bytes.ptr, &emitted);
    for (0..(order - 1)) |index| bytes[cycle_length + index] = bytes[index];
    return @intCast(output_length);
}
