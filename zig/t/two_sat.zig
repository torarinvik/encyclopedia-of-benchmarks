const MaxLits = 80;
fn visitOrder(graph: *const [6400]bool, n: usize, v: usize, seen: *[80]bool, order: *[80]usize, count: *usize) void {
    seen[v] = true;
    for (0..n) |w| if (graph[v * MaxLits + w] and !seen[w]) visitOrder(graph, n, w, seen, order, count);
    order[count.*] = v; count.* += 1;
}
fn visitComponent(graph: *const [6400]bool, n: usize, v: usize, comp: *[80]i32, id: i32) void {
    comp[v] = id;
    for (0..n) |w| if (graph[v * MaxLits + w] and comp[w] < 0) visitComponent(graph, n, w, comp, id);
}
export fn two_sat(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 4096) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 40 or values[1] < 0 or values[1] > 2047) return -1;
    const variables: usize = @intCast(values[0]); const clauses: usize = @intCast(values[1]);
    if (length != 2 + 2 * clauses) return -1;
    const n = variables * 2;
    var graph = @as([6400]bool, @splat(false)); var transpose = @as([6400]bool, @splat(false));
    for (0..clauses) |i| {
        const a = values[2 + 2 * i]; const b = values[3 + 2 * i];
        if (a == 0 or b == 0 or @abs(a) > values[0] or @abs(b) > values[0]) return -1;
        const x: usize = 2 * (@as(usize, @intCast(@abs(a))) - 1) + @intFromBool(a < 0);
        const y: usize = 2 * (@as(usize, @intCast(@abs(b))) - 1) + @intFromBool(b < 0);
        graph[(x ^ 1) * MaxLits + y] = true; transpose[y * MaxLits + (x ^ 1)] = true;
        graph[(y ^ 1) * MaxLits + x] = true; transpose[x * MaxLits + (y ^ 1)] = true;
    }
    var seen = @as([80]bool, @splat(false)); var order = @as([80]usize, @splat(0)); var count: usize = 0;
    for (0..n) |v| if (!seen[v]) visitOrder(&graph, n, v, &seen, &order, &count);
    var comp = @as([80]i32, @splat(-1)); var id: i32 = 0;
    while (count > 0) { count -= 1; const v = order[count]; if (comp[v] < 0) { visitComponent(&transpose, n, v, &comp, id); id += 1; } }
    var sat = true; for (0..variables) |i| if (comp[2*i] == comp[2*i+1]) { sat = false; };
    const outlen = if (sat) variables + 1 else 1;
    if (output == null or capacity < outlen) return -2;
    output.?[0] = @intFromBool(sat);
    if (sat) for (0..variables) |i| { output.?[i+1] = @intFromBool(comp[2*i] > comp[2*i+1]); };
    return @intCast(outlen);
}
