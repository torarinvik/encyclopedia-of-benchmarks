const MAX_N: usize = 512;
const MODULUS: i64 = 998244353;

fn modPow(base_value: i64, exponent_value: usize) i64 {
    var result: i64 = 1;
    var base = base_value;
    var exponent = exponent_value;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn solve(n: usize) i64 {
    var factorial = [_]i64{0} ** (MAX_N + 1);
    var inverse_factorial = [_]i64{0} ** (MAX_N + 1);
    var all_graphs = [_]i64{0} ** (MAX_N + 1);
    var connected = [_]i64{0} ** (MAX_N + 1);
    factorial[0] = 1;
    for (1..n + 1) |i| factorial[i] = @mod(factorial[i - 1] * @as(i64, @intCast(i)), MODULUS);
    inverse_factorial[n] = modPow(factorial[n], 998244351);
    var i = n;
    while (i > 0) : (i -= 1) {
        inverse_factorial[i - 1] = @mod(inverse_factorial[i] * @as(i64, @intCast(i)), MODULUS);
    }

    all_graphs[0] = 1;
    var edge_choices: i64 = 1;
    for (1..n + 1) |size| {
        all_graphs[size] = @mod(all_graphs[size - 1] * edge_choices, MODULUS);
        edge_choices = @mod(edge_choices * 2, MODULUS);
    }
    connected[1] = 1;
    for (2..n + 1) |size| {
        var disconnected: i64 = 0;
        for (1..size) |component_size| {
            var choose = @mod(factorial[size - 1] * inverse_factorial[component_size - 1], MODULUS);
            choose = @mod(choose * inverse_factorial[size - component_size], MODULUS);
            var term = @mod(choose * connected[component_size], MODULUS);
            term = @mod(term * all_graphs[size - component_size], MODULUS);
            disconnected = @mod(disconnected + term, MODULUS);
        }
        connected[size] = @mod(all_graphs[size] - disconnected + MODULUS, MODULUS);
    }
    return connected[n];
}

export fn connected_labeled_graph_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    return solve(@intCast(input[0]));
}
