const std = @import("std");

const Search = struct {
    n: usize, goal: usize, bound: i32, next: i32,
    h: [12]i32 = @splat(0), edges: [12]u16 = @splat(0),

    fn visit(self: *Search, u: usize, depth: i32, path: u16) i32 {
        const score = depth + self.h[u];
        if (score > self.bound) { self.next = @min(self.next, score); return -1; }
        if (u == self.goal) return depth;
        for (0..self.n) |v| {
            const bit = @as(u16, 1) << @intCast(v);
            if (self.edges[u] & bit != 0 and path & bit == 0) {
                const found = self.visit(v, depth + 1, path | bit);
                if (found >= 0) return found;
            }
        }
        return -1;
    }
};

export fn ida_star_graph(values: [*c]const i64, length: usize) i64 {
    const invalid = std.math.minInt(i64);
    if (values == null or length < 5 or length > 112) return invalid;
    const n0 = values[0]; const m0 = values[1];
    const start0 = values[2]; const goal0 = values[3];
    if (n0 < 1 or n0 > 12 or m0 < 0 or m0 > 48 or start0 < 0 or start0 >= n0 or
        goal0 < 0 or goal0 >= n0 or length != @as(usize, @intCast(4+n0+2*m0))) return invalid;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    const start: usize = @intCast(start0); const goal: usize = @intCast(goal0);
    var s = Search{ .n = n, .goal = goal, .bound = 0, .next = 0 };
    for (0..n) |i| {
        if (values[4+i] < 0 or values[4+i] >= n0) return invalid;
        s.h[i] = @intCast(values[4+i]);
    }
    if (s.h[goal] != 0) return invalid;
    for (0..m) |i| {
        const u0 = values[4+n+2*i]; const v0 = values[5+n+2*i];
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0) return invalid;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        const bit = @as(u16, 1) << @intCast(v);
        if (s.edges[u] & bit != 0 or s.h[u] > s.h[v] + 1) return invalid;
        s.edges[u] |= bit;
    }
    s.bound = s.h[start];
    while (true) {
        s.next = 1000;
        const found = s.visit(start, 0, @as(u16, 1) << @intCast(start));
        if (found >= 0) return found;
        if (s.next == 1000) return -1;
        s.bound = s.next;
    }
}
