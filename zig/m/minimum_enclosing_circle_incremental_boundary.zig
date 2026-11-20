// Independently authored draft; not compiled or run.
const Point = struct { x: i64, y: i64 };
const Circle = struct { x: i64, y: i64, den: i64, radius2: i64 };
fn distance(c: Circle, p: Point) i64 {
    const dx = p.x*c.den-c.x; const dy = p.y*c.den-c.y;
    return dx*dx+dy*dy;
}
fn pointCircle(p: Point) Circle { return .{ .x=p.x, .y=p.y, .den=1, .radius2=0 }; }
fn pairCircle(a: Point, b: Point) Circle {
    var c = Circle{ .x=a.x+b.x, .y=a.y+b.y, .den=2, .radius2=0 };
    c.radius2 = distance(c,a);
    return c;
}
fn tripleCircle(a: Point, b: Point, c: Point) Circle {
    var den = 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));
    if (den == 0) {
        const ab = pairCircle(a,b); const ac = pairCircle(a,c); const bc = pairCircle(b,c);
        if (ab.radius2 >= ac.radius2 and ab.radius2 >= bc.radius2) return ab;
        return if (ac.radius2 >= bc.radius2) ac else bc;
    }
    const aa = a.x*a.x+a.y*a.y; const bb = b.x*b.x+b.y*b.y; const cc = c.x*c.x+c.y*c.y;
    var x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y);
    var y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x);
    if (den < 0) { den = -den; x = -x; y = -y; }
    var result = Circle{ .x=x, .y=y, .den=den, .radius2=0 };
    result.radius2 = distance(result,a);
    return result;
}
export fn minimum_enclosing_circle_incremental_boundary(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > 194 or input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1+3*n) return -1;
    var points: [64]Point = undefined;
    var order: [64]usize = undefined;
    var seen: [64]bool = @splat(false);
    for (0..n) |i| {
        const x = input[1+2*i]; const y = input[2+2*i];
        if (x < -100 or x > 100 or y < -100 or y > 100) return -1;
        points[i] = .{ .x=x, .y=y };
    }
    for (0..n) |i| {
        const v = input[1+2*n+i];
        if (v < 0 or v >= input[0]) return -1;
        const index: usize = @intCast(v);
        if (seen[index]) return -1;
        seen[index] = true; order[i] = index;
    }
    const output = output_opt orelse return -2;
    if (capacity < n) return -2;
    var circle = pointCircle(points[order[0]]);
    for (1..n) |i| {
        const a = points[order[i]];
        if (distance(circle,a) <= circle.radius2) continue;
        circle = pointCircle(a);
        for (0..i) |j| {
            const b = points[order[j]];
            if (distance(circle,b) <= circle.radius2) continue;
            circle = pairCircle(a,b);
            for (0..j) |k| {
                const c = points[order[k]];
                if (distance(circle,c) > circle.radius2) circle = tripleCircle(a,b,c);
            }
        }
    }
    for (0..n) |i| output[i] = if (distance(circle,points[i]) == circle.radius2) 1 else 0;
    return @intCast(n);
}
