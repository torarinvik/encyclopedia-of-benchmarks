const Point = struct { x: i64, y: i64 };
fn turn(p: *const [32]Point, a: usize, b: usize, c: usize) i64 {
    return (p[b].x-p[a].x)*(p[c].y-p[a].y) - (p[b].y-p[a].y)*(p[c].x-p[a].x);
}

export fn melkman_simple_polyline_hull(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > 66) return -1;
    const input = input_opt.?;
    const raw = input[0];
    if (raw < 3 or raw > 32) return -1;
    const n: usize = @intCast(raw);
    if (length != 1+2*n) return -1;
    var points: [32]Point = undefined;
    for (0..n) |i| {
        const x = input[1+2*i]; const y = input[2+2*i];
        if (x < -1000 or x > 1000 or y < -1000 or y > 1000) return -1;
        points[i] = .{ .x = x, .y = y };
    }
    const initial = turn(&points,0,1,2);
    if (initial == 0) return -1;
    var deque: [68]usize = @splat(0);
    var first: usize = 32;
    var last: usize = 35;
    deque[32] = 2; deque[35] = 2;
    deque[33] = if (initial > 0) 0 else 1;
    deque[34] = if (initial > 0) 1 else 0;
    for (3..n) |i| {
        if (turn(&points,deque[first],deque[first+1],i) > 0 and turn(&points,deque[last-1],deque[last],i) > 0) continue;
        while (last > first and turn(&points,deque[first],deque[first+1],i) <= 0) first += 1;
        if (last <= first or first == 0) return -1;
        first -= 1; deque[first] = i;
        while (last > first and turn(&points,deque[last-1],deque[last],i) <= 0) last -= 1;
        if (last <= first or last+1 >= 68) return -1;
        last += 1; deque[last] = i;
    }
    const count = last-first;
    var start: usize = 0;
    for (1..count) |i| {
        const a = points[deque[first+i]]; const b = points[deque[first+start]];
        if (a.x < b.x or (a.x == b.x and a.y < b.y)) start = i;
    }
    const bytes = 8*count;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [256]u8 = @splat(0);
    for (0..count) |i| {
        const index: u64 = @intCast(deque[first+(start+i)%count]);
        for (0..8) |b| staged[8*i+b] = @truncate(index >> @intCast(8*b));
    }
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = staged[i];
    return @intCast(bytes);
}
