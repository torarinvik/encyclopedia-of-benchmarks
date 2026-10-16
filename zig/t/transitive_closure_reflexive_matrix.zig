const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = MAX_VERTICES * (MAX_VERTICES - 1);
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_CELLS: usize = MAX_VERTICES * MAX_VERTICES;

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn transitive_closure_reflexive_matrix(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > MAX_VERTICES) return -1;
    const n: usize = @intCast(n_value);
    const m_value = input[1];
    if (m_value < 0 or m_value > @as(i64, @intCast(n * (n - 1)))) return -1;
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var reach: [MAX_CELLS]i64 = @splat(0);
    for (0..n) |i| reach[i * n + i] = 1;
    for (0..m) |edge| {
        const from_value = input[2 + 2 * edge];
        const to_value = input[3 + 2 * edge];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n)) or to_value < 0 or to_value >= @as(i64, @intCast(n)) or from_value == to_value) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        if (reach[from * n + to] != 0) return -1;
        reach[from * n + to] = 1;
    }
    for (0..n) |k| {
        for (0..n) |i| {
            if (reach[i * n + k] == 1) {
                for (0..n) |j| {
                    if (reach[k * n + j] == 1) reach[i * n + j] = 1;
                }
            }
        }
    }

    const output_bytes = n * n * 8;
    if (output == null or capacity < output_bytes) return -2;
    for (0..n * n) |index| putI64Le(output, index * 8, reach[index]);
    return @intCast(output_bytes);
}
