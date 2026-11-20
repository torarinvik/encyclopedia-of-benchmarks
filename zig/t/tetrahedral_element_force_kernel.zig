const MAX_ELEMENTS: usize = 32;
const MAX_VALID_INPUT: usize = 3 + 12 * MAX_ELEMENTS;
const MAX_INPUT: usize = MAX_VALID_INPUT + 1;
const MAX_OUTPUT: usize = 3072;

fn storeI64LE(output: *[MAX_OUTPUT]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tetrahedral_element_force_kernel(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const m_value = input[0];
    const lambda = input[1];
    const mu = input[2];
    if (m_value < 1 or m_value > @as(i64, @intCast(MAX_ELEMENTS)) or lambda < 0 or lambda > 16 or mu < 0 or mu > 16)
        return -1;
    const m: usize = @intCast(m_value);
    if (length != 3 + 12 * m) return -1;
    for (3..length) |index| {
        if (input[index] < -4 or input[index] > 4) return -1;
    }

    const required = 96 * m;
    if (output_opt == null or capacity < required) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    for (0..m) |element| {
        const base = 3 + 12 * element;
        var deformation: [3][3]i64 = undefined;
        for (0..3) |row| {
            for (0..3) |column| {
                deformation[row][column] = input[base + 3 * (column + 1) + row] - input[base + row];
            }
        }
        const trace_delta = deformation[0][0] + deformation[1][1] + deformation[2][2] - 3;
        var stress: [3][3]i64 = undefined;
        for (0..3) |row| {
            for (0..3) |column| {
                const diagonal: i64 = if (row == column) 1 else 0;
                stress[row][column] = lambda * trace_delta * diagonal +
                    mu * (deformation[row][column] + deformation[column][row] - 2 * diagonal);
            }
        }
        for (0..3) |axis| {
            const vertex_zero = stress[axis][0] + stress[axis][1] + stress[axis][2];
            storeI64LE(&staged, 8 * (12 * element + axis), vertex_zero);
            for (1..4) |vertex| {
                storeI64LE(&staged, 8 * (12 * element + 3 * vertex + axis), -stress[axis][vertex - 1]);
            }
        }
    }
    const output = output_opt.?;
    for (0..required) |byte| output[byte] = staged[byte];
    return @intCast(required);
}
