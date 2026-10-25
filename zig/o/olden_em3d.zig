const MAX_NODES: usize = 8;
const MAX_DEGREE: usize = 4;

export fn olden_em3d(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 2) return -1;
    const rn = input[0]; const rd = input[1];
    if (rn != rn or rd != rd or rn < 1.0 or rn > 8.0 or @as(f64, @floatFromInt(@as(usize, @intFromFloat(rn)))) != rn or
        rd < 1.0 or rd > 4.0 or @as(f64, @floatFromInt(@as(usize, @intFromFloat(rd)))) != rd) return -1;
    const n: usize = @intFromFloat(rn); const degree: usize = @intFromFloat(rd);
    const edges = n * degree;
    if (input_length != 2 + 2*n + 4*edges) return -1;
    var electric: [MAX_NODES]f64 = undefined; var magnetic: [MAX_NODES]f64 = undefined;
    var offset: usize = 2;
    for (0..n) |i| { const value = input[offset+i]; if (value != value or value < 0.0 or value > 1.0) return -1; electric[i] = value; }
    offset += n;
    for (0..n) |i| { const value = input[offset+i]; if (value != value or value < 0.0 or value > 1.0) return -1; magnetic[i] = value; }
    offset += n;
    const e_neighbors = offset; offset += edges;
    const e_coefficients = offset; offset += edges;
    const h_neighbors = offset; offset += edges;
    const h_coefficients = offset;
    for (0..edges) |i| {
        const en = input[e_neighbors+i]; const hn = input[h_neighbors+i];
        if (en != en or en < 0.0 or en >= @as(f64, @floatFromInt(n)) or @as(f64, @floatFromInt(@as(usize, @intFromFloat(en)))) != en or
            hn != hn or hn < 0.0 or hn >= @as(f64, @floatFromInt(n)) or @as(f64, @floatFromInt(@as(usize, @intFromFloat(hn)))) != hn) return -1;
        if (input[e_coefficients+i] != input[e_coefficients+i] or input[e_coefficients+i] < 0.0 or input[e_coefficients+i] > 1.0 or input[h_coefficients+i] != input[h_coefficients+i] or input[h_coefficients+i] < 0.0 or input[h_coefficients+i] > 1.0) return -1;
        const start = (i / degree) * degree;
        for (start..i) |j| if (input[e_neighbors+j] == en or input[h_neighbors+j] == hn) return -1;
    }
    if (output == null or output_capacity < 2*n) return -2;
    for (0..n) |node| {
        var current = electric[node]; const base = node * degree;
        for (0..degree) |edge| { const coefficient = base + (edge & ~@as(usize, 1)); current -= input[e_coefficients+coefficient] * magnetic[@intFromFloat(input[e_neighbors+base+edge])]; }
        electric[node] = current;
    }
    for (0..n) |node| {
        var current = magnetic[node]; const base = node * degree;
        for (0..degree) |edge| { const coefficient = base + (edge & ~@as(usize, 1)); current -= input[h_coefficients+coefficient] * electric[@intFromFloat(input[h_neighbors+base+edge])]; }
        magnetic[node] = current;
    }
    for (0..n) |i| { output[i] = electric[i]; output[n+i] = magnetic[i]; }
    return @intCast(2*n);
}
