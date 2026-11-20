const std = @import("std");
const N: usize = 8;
const M: usize = 28;
const MAX_INPUT: usize = 59;

fn recurse(vertices: u16, graph: [N]u16) u64 {
    var complete = true;
    for (0..N) |u| {
        if ((vertices & (@as(u16, 1) << @intCast(u))) != 0) {
            const others = vertices & ~(@as(u16, 1) << @intCast(u));
            if ((graph[u] & others) != others) complete = false;
        }
    }
    if (complete) return 0;
    var pivot: usize = 0;
    while ((vertices & (@as(u16, 1) << @intCast(pivot))) == 0 or
        (graph[pivot] & (vertices & ~(@as(u16, 1) << @intCast(pivot)))) == (vertices & ~(@as(u16, 1) << @intCast(pivot)))) : (pivot += 1) {}
    const a = (@as(u16, 1) << @intCast(pivot)) | graph[pivot] & vertices;
    var unseen = vertices & ~a;
    var components = [_]u16{0} ** N;
    var closures = [_]u16{0} ** N;
    var count: usize = 0;
    while (unseen != 0) {
        const seed: usize = @intCast(@ctz(unseen));
        var comp = @as(u16, 1) << @intCast(seed);
        unseen &= ~comp;
        var frontier = comp;
        while (frontier != 0) {
            const u: usize = @intCast(@ctz(frontier));
            frontier &= ~(@as(u16, 1) << @intCast(u));
            const added = graph[u] & unseen;
            comp |= added; frontier |= added; unseen &= ~added;
        }
        components[count] = comp; count += 1;
    }
    var saturated = graph;
    var result: u64 = 0;
    for (0..count) |ci| {
        const comp = components[ci];
        var boundary: u16 = 0;
        for (0..N) |u| if ((comp & (@as(u16, 1) << @intCast(u))) != 0) {
            boundary |= graph[u] & vertices & ~comp;
        };
        closures[ci] = comp | boundary;
        for (0..N) |u| if ((boundary & (@as(u16, 1) << @intCast(u))) != 0) {
            var v = u + 1;
            while (v < N) : (v += 1) if ((boundary & (@as(u16, 1) << @intCast(v))) != 0 and
                (saturated[u] & (@as(u16, 1) << @intCast(v))) == 0) {
                saturated[u] |= @as(u16, 1) << @intCast(v);
                saturated[v] |= @as(u16, 1) << @intCast(u);
                result |= @as(u64, 1) << @intCast(u * N + v);
            };
        };
    }
    result |= recurse(a, saturated);
    for (closures[0..count]) |closure| result |= recurse(closure, saturated);
    return result;
}

fn putWord(output: [*]u8, at: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |b| output[at + b] = @truncate(bytes >> @intCast(8 * b));
}

export fn fast_minimal_triangulation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > N or m64 < 0 or m64 > M or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var graph = [_]u16{0} ** N;
    var original: u64 = 0;
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |i| {
        const u = input[2 + 2 * i]; const v = input[3 + 2 * i];
        if (u < 0 or v <= u or v >= n64 or u < previous_u or (u == previous_u and v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        const ui: usize = @intCast(u); const vi: usize = @intCast(v);
        graph[ui] |= @as(u16, 1) << @intCast(vi); graph[vi] |= @as(u16, 1) << @intCast(ui);
        original |= @as(u64, 1) << @intCast(ui * N + vi);
    }
    const vertices = (@as(u16, 1) << @intCast(n)) - 1;
    const fill = recurse(vertices, graph) & ~original;
    var count: usize = 0;
    for (0..n) |u| {
        for (u + 1..n) |v| {
            if ((fill & (@as(u64, 1) << @intCast(u * N + v))) != 0) count += 1;
        }
    }
    const bytes = 8 * (1 + 2 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    putWord(output, 0, @intCast(count));
    var index: usize = 1;
    for (0..n) |u| {
        for (u + 1..n) |v| {
            if ((fill & (@as(u64, 1) << @intCast(u * N + v))) != 0) {
                putWord(output, 8 * index, @intCast(u)); index += 1;
                putWord(output, 8 * index, @intCast(v)); index += 1;
            }
        }
    }
    return @intCast(bytes);
}
