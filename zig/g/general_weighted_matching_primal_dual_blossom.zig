/// Primal-dual weighted matching with odd-cycle contraction.
const std = @import("std");
const MAX_N: usize = 64;
const IDS: usize = 2 * MAX_N;
const SLOTS: usize = IDS + 1;
const INF: i64 = std.math.maxInt(i64);

const Search = struct {
    n: usize = 0,
    nodes: usize = 0,
    epoch: i32 = 0,
    weight: [SLOTS][SLOTS]i64 = [_][SLOTS]i64{[_]i64{0} ** SLOTS} ** SLOTS,
    dual: [SLOTS]i64 = [_]i64{0} ** SLOTS,
    edge_a: [SLOTS][SLOTS]i16 = [_][SLOTS]i16{[_]i16{0} ** SLOTS} ** SLOTS,
    edge_b: [SLOTS][SLOTS]i16 = [_][SLOTS]i16{[_]i16{0} ** SLOTS} ** SLOTS,
    mate: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    slack_from: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    top: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    parent: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    state: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    seen: [SLOTS]i32 = [_]i32{0} ** SLOTS,
    members: [SLOTS][SLOTS]i16 = [_][SLOTS]i16{[_]i16{0} ** SLOTS} ** SLOTS,
    member_count: [SLOTS]i16 = [_]i16{0} ** SLOTS,
    child_of: [SLOTS][MAX_N + 1]i16 = [_][MAX_N + 1]i16{[_]i16{0} ** (MAX_N + 1)} ** SLOTS,
    queue: [MAX_N]usize = [_]usize{0} ** MAX_N,
    queued: [MAX_N + 1]bool = [_]bool{false} ** (MAX_N + 1),
    head: usize = 0,
    tail: usize = 0,
    count: usize = 0,

    fn delta(self: *const Search, a: usize, b: usize) i64 {
        const x: usize = @intCast(self.edge_a[a][b]);
        const y: usize = @intCast(self.edge_b[a][b]);
        return self.dual[x] + self.dual[y] - 2 * self.weight[a][b];
    }

    fn enqueueLeaf(self: *Search, v: usize) void {
        if (v == 0 or v > self.n or self.queued[v]) return;
        self.queue[self.tail] = v;
        self.tail = (self.tail + 1) % self.n;
        self.count += 1;
        self.queued[v] = true;
    }

    fn enqueueMembers(self: *Search, x: usize) void {
        if (x <= self.n) { self.enqueueLeaf(x); return; }
        const size: usize = @intCast(self.member_count[x]);
        for (0..size) |i| self.enqueueMembers(@intCast(self.members[x][i]));
    }

    fn setTop(self: *Search, x: usize, b: usize) void {
        self.top[x] = @intCast(b);
        if (x > self.n) {
            const size: usize = @intCast(self.member_count[x]);
            for (0..size) |i| self.setTop(@intCast(self.members[x][i]), b);
        }
    }

    fn updateSlack(self: *Search, u: usize, x: usize) void {
        const old: usize = @intCast(self.slack_from[x]);
        if (old == 0 or self.delta(u, x) < self.delta(old, x)) self.slack_from[x] = @intCast(u);
    }

    fn refreshSlack(self: *Search, x: usize) void {
        self.slack_from[x] = 0;
        for (1..self.n + 1) |u| {
            const representative: usize = @intCast(self.top[u]);
            if (self.weight[u][x] > 0 and representative != x and self.state[representative] == 0)
                self.updateSlack(u, x);
        }
    }

    fn cyclePosition(self: *Search, b: usize, child: usize) usize {
        const size: usize = @intCast(self.member_count[b]);
        var pos: usize = 0;
        while (pos < size and @as(usize, @intCast(self.members[b][pos])) != child) : (pos += 1) {}
        if (pos == size) return 0;
        if (pos % 2 == 1) {
            var left: usize = 1;
            var right = size - 1;
            while (left < right) : ({ left += 1; right -= 1; }) {
                const tmp = self.members[b][left];
                self.members[b][left] = self.members[b][right];
                self.members[b][right] = tmp;
            }
            pos = size - pos;
        }
        return pos;
    }

    fn rotateCycle(self: *Search, b: usize, start: usize) void {
        const size: usize = @intCast(self.member_count[b]);
        var saved: [SLOTS]i16 = [_]i16{0} ** SLOTS;
        for (0..size) |i| saved[i] = self.members[b][(i + start) % size];
        for (0..size) |i| self.members[b][i] = saved[i];
    }

    fn setPair(self: *Search, u: usize, v: usize) void {
        self.mate[u] = self.edge_b[u][v];
        if (u <= self.n) return;
        const leaf: usize = @intCast(self.edge_a[u][v]);
        const entry: usize = @intCast(self.child_of[u][leaf]);
        const pos = self.cyclePosition(u, entry);
        for (0..pos) |i| self.setPair(@intCast(self.members[u][i]), @intCast(self.members[u][i ^ 1]));
        self.setPair(entry, v);
        self.rotateCycle(u, pos);
    }

    fn augment(self: *Search, u_start: usize, v_start: usize) void {
        var u = u_start;
        var v = v_start;
        while (true) {
            const next: usize = @intCast(self.top[@as(usize, @intCast(self.mate[u]))]);
            self.setPair(u, v);
            if (next == 0) return;
            const prior: usize = @intCast(self.top[@as(usize, @intCast(self.parent[next]))]);
            self.setPair(next, prior);
            u = prior;
            v = next;
        }
    }

    fn commonBase(self: *Search, u_start: usize, v_start: usize) usize {
        self.epoch += 1;
        var u = u_start;
        var v = v_start;
        while (u != 0 or v != 0) {
            if (u != 0) {
                if (self.seen[u] == self.epoch) return u;
                self.seen[u] = self.epoch;
                u = @intCast(self.top[@as(usize, @intCast(self.mate[u]))]);
                if (u != 0) u = @intCast(self.top[@as(usize, @intCast(self.parent[u]))]);
            }
            const tmp = u;
            u = v;
            v = tmp;
        }
        return 0;
    }

    fn addChild(self: *Search, b: usize, x: usize) void {
        const at: usize = @intCast(self.member_count[b]);
        self.members[b][at] = @intCast(x);
        self.member_count[b] += 1;
    }

    fn contract(self: *Search, u: usize, base: usize, v: usize) void {
        var b = self.n + 1;
        while (b <= self.nodes and self.top[b] != 0) : (b += 1) {}
        if (b > self.nodes) self.nodes += 1;
        self.dual[b] = 0;
        self.state[b] = 0;
        self.mate[b] = self.mate[base];
        self.member_count[b] = 0;
        self.addChild(b, base);
        var x = u;
        while (x != base) {
            self.addChild(b, x);
            const y: usize = @intCast(self.top[@as(usize, @intCast(self.mate[x]))]);
            self.addChild(b, y);
            self.enqueueMembers(y);
            x = @intCast(self.top[@as(usize, @intCast(self.parent[y]))]);
        }
        const end: usize = @intCast(self.member_count[b]);
        var left: usize = 1;
        var right = end - 1;
        while (left < right) : ({ left += 1; right -= 1; }) {
            const tmp = self.members[b][left];
            self.members[b][left] = self.members[b][right];
            self.members[b][right] = tmp;
        }
        x = v;
        while (x != base) {
            self.addChild(b, x);
            const y: usize = @intCast(self.top[@as(usize, @intCast(self.mate[x]))]);
            self.addChild(b, y);
            self.enqueueMembers(y);
            x = @intCast(self.top[@as(usize, @intCast(self.parent[y]))]);
        }
        self.setTop(b, b);

        for (1..self.nodes + 1) |y| {
            self.weight[b][y] = 0; self.weight[y][b] = 0;
            self.edge_a[b][y] = 0; self.edge_b[b][y] = 0;
            self.edge_a[y][b] = 0; self.edge_b[y][b] = 0;
        }
        for (0..MAX_N + 1) |leaf| self.child_of[b][leaf] = 0;
        const count: usize = @intCast(self.member_count[b]);
        for (0..count) |i| {
            const child: usize = @intCast(self.members[b][i]);
            for (1..self.nodes + 1) |y| {
                if (self.weight[child][y] == 0) continue;
                if (self.weight[b][y] == 0 or self.delta(child, y) < self.delta(b, y)) {
                    self.weight[b][y] = self.weight[child][y];
                    self.edge_a[b][y] = self.edge_a[child][y];
                    self.edge_b[b][y] = self.edge_b[child][y];
                    self.weight[y][b] = self.weight[y][child];
                    self.edge_a[y][b] = self.edge_a[y][child];
                    self.edge_b[y][b] = self.edge_b[y][child];
                }
            }
            for (1..self.n + 1) |leaf| {
                const contains = if (child <= self.n) child == leaf else self.child_of[child][leaf] != 0;
                if (contains) self.child_of[b][leaf] = @intCast(child);
            }
        }
        self.refreshSlack(b);
    }

    fn expand(self: *Search, b: usize) void {
        const count: usize = @intCast(self.member_count[b]);
        for (0..count) |i| {
            const child: usize = @intCast(self.members[b][i]);
            self.setTop(child, child);
        }
        const outside: usize = @intCast(self.parent[b]);
        const entry_leaf: usize = @intCast(self.edge_a[b][outside]);
        const entry: usize = @intCast(self.child_of[b][entry_leaf]);
        const pos = self.cyclePosition(b, entry);
        var i: usize = 0;
        while (i < pos) : (i += 2) {
            const inner: usize = @intCast(self.members[b][i]);
            const outer: usize = @intCast(self.members[b][i + 1]);
            self.parent[inner] = self.edge_a[outer][inner];
            self.state[inner] = 1;
            self.state[outer] = 0;
            self.slack_from[inner] = 0;
            self.refreshSlack(outer);
            self.enqueueMembers(outer);
        }
        self.state[entry] = 1;
        self.parent[entry] = @intCast(outside);
        for (pos + 1..count) |j| {
            const child: usize = @intCast(self.members[b][j]);
            self.state[child] = -1;
            self.refreshSlack(child);
        }
        self.top[b] = 0;
    }

    fn processEdge(self: *Search, left: usize, right: usize) bool {
        const u: usize = @intCast(self.top[left]);
        const v: usize = @intCast(self.top[right]);
        if (self.state[v] == -1) {
            self.parent[v] = @intCast(left);
            self.state[v] = 1;
            const next: usize = @intCast(self.top[@as(usize, @intCast(self.mate[v]))]);
            self.slack_from[v] = 0; self.slack_from[next] = 0;
            self.state[next] = 0;
            self.enqueueMembers(next);
        } else if (self.state[v] == 0) {
            const base = self.commonBase(u, v);
            if (base == 0) {
                self.augment(u, v);
                self.augment(v, u);
                return true;
            }
            self.contract(u, base, v);
        }
        return false;
    }

    fn stage(self: *Search) bool {
        for (0..self.nodes + 1) |x| { self.state[x] = -1; self.slack_from[x] = 0; }
        self.head = 0; self.tail = 0; self.count = 0;
        for (0..MAX_N + 1) |i| self.queued[i] = false;
        for (1..self.nodes + 1) |x| {
            if (self.top[x] == @as(i16, @intCast(x)) and self.mate[x] == 0) {
                self.parent[x] = 0;
                self.state[x] = 0;
                self.enqueueMembers(x);
            }
        }
        if (self.count == 0) return false;

        while (true) {
            while (self.count != 0) {
                const u = self.queue[self.head];
                self.head = (self.head + 1) % self.n;
                self.count -= 1;
                self.queued[u] = false;
                if (self.state[@as(usize, @intCast(self.top[u]))] == 1) continue;
                for (1..self.n + 1) |v| {
                    if (self.weight[u][v] == 0 or self.top[u] == self.top[v]) continue;
                    if (self.delta(u, v) == 0) {
                        const left: usize = @intCast(self.edge_a[u][v]);
                        const right: usize = @intCast(self.edge_b[u][v]);
                        if (self.processEdge(left, right)) return true;
                    } else {
                        self.updateSlack(u, @intCast(self.top[v]));
                    }
                }
            }

            var step = INF;
            for (1..self.n + 1) |u|
                if (self.state[@as(usize, @intCast(self.top[u]))] == 0) { step = @min(step, self.dual[u]); };
            for (self.n + 1..self.nodes + 1) |b|
                if (self.top[b] == @as(i16, @intCast(b)) and self.state[b] == 1) { step = @min(step, @divTrunc(self.dual[b], 2)); };
            for (1..self.nodes + 1) |x| {
                if (self.top[x] != @as(i16, @intCast(x)) or self.slack_from[x] == 0) continue;
                const from: usize = @intCast(self.slack_from[x]);
                const slack = self.delta(from, x);
                if (self.state[x] == -1) step = @min(step, slack)
                else if (self.state[x] == 0) step = @min(step, @divTrunc(slack, 2));
            }
            if (step == INF) return false;

            for (1..self.n + 1) |u| {
                const state = self.state[@as(usize, @intCast(self.top[u]))];
                if (state == 0) {
                    if (self.dual[u] == step) return false;
                    self.dual[u] -= step;
                } else if (state == 1) self.dual[u] += step;
            }
            for (self.n + 1..self.nodes + 1) |b| {
                if (self.top[b] != @as(i16, @intCast(b))) continue;
                if (self.state[b] == 0) self.dual[b] += 2 * step
                else if (self.state[b] == 1) self.dual[b] -= 2 * step;
            }
            for (1..self.nodes + 1) |x| {
                if (self.top[x] != @as(i16, @intCast(x)) or self.slack_from[x] == 0) continue;
                const from: usize = @intCast(self.slack_from[x]);
                if (self.top[from] != @as(i16, @intCast(x)) and self.delta(from, x) == 0) {
                    if (self.processEdge(@intCast(self.edge_a[from][x]), @intCast(self.edge_b[from][x]))) return true;
                }
            }
            for (self.n + 1..self.nodes + 1) |b|
                if (self.top[b] == @as(i16, @intCast(b)) and self.state[b] == 1 and self.dual[b] == 0) self.expand(b);
        }
    }
};

export fn general_weighted_matching_primal_dual_blossom(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 6051) return -2;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > n_value * (n_value - 1) / 2) return -2;
    const n: usize = @intCast(n_value);
    const edges: usize = @intCast(m_value);
    if (length != 2 + 3 * edges) return -2;

    var search = Search{};
    search.n = n;
    search.nodes = n;
    var largest: i64 = 0;
    for (0..edges) |index| {
        const uv = input[2 + 3 * index];
        const vv = input[3 + 3 * index];
        const weight = input[4 + 3 * index];
        if (uv < 0 or uv >= n_value or vv < 0 or vv >= n_value or uv == vv or weight < 1 or weight > 1_000_000) return -2;
        const u: usize = @intCast(uv + 1);
        const v: usize = @intCast(vv + 1);
        if (search.weight[u][v] != 0) return -2;
        search.weight[u][v] = weight; search.weight[v][u] = weight;
        search.edge_a[u][v] = @intCast(u); search.edge_b[u][v] = @intCast(v);
        search.edge_a[v][u] = @intCast(v); search.edge_b[v][u] = @intCast(u);
        largest = @max(largest, weight);
    }
    for (1..n + 1) |u| {
        search.top[u] = @intCast(u);
        search.dual[u] = largest;
        search.child_of[u][u] = @intCast(u);
    }
    while (search.stage()) {}
    var answer: i64 = 0;
    for (1..n + 1) |u| {
        const v: usize = @intCast(search.mate[u]);
        if (v > u) answer += search.weight[u][v];
    }
    return answer;
}

