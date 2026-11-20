const N: usize = 256;
const OPS: usize = 40;
const WORDS: usize = 82;

const Table = struct {
    directory: [N]u8 = [_]u8{0} ** N,
    keys: [N][2]u8 = [_][2]u8{[_]u8{0} ** 2} ** N,
    counts: [N]u8 = [_]u8{0} ** N,
    depths: [N]u8 = [_]u8{0} ** N,
    active: [N]bool = [_]bool{false} ** N,
    gd: usize = 1,
    high: usize = 1,
    buckets: usize = 2,
    live: usize = 0,

    fn init() Table {
        var t = Table{};
        t.directory[0] = 0; t.directory[1] = 1;
        t.active[0] = true; t.active[1] = true;
        t.depths[0] = 1; t.depths[1] = 1;
        return t;
    }
    fn bucket(t: *const Table, key: usize) usize { return @intCast(t.directory[key & ((@as(usize, 1) << t.gd) - 1)]); }
    fn find(t: *const Table, b: usize, key: u8) ?usize {
        const n: usize = t.counts[b];
        for (0..n) |slot| if (t.keys[b][slot] == key) return slot;
        return null;
    }
    fn split(t: *Table, b: usize) bool {
        const d: usize = @intCast(t.depths[b]);
        if (d >= 8) return false;
        if (d == t.gd) {
            const old_size = @as(usize, 1) << t.gd;
            for (0..old_size) |i| t.directory[i + old_size] = t.directory[i];
            t.gd += 1; t.high = @max(t.high, t.gd);
        }
        var fresh: usize = 0;
        while (fresh < N and t.active[fresh]) : (fresh += 1) {}
        if (fresh == N) return false;
        t.active[fresh] = true; t.depths[b] = @intCast(d + 1); t.depths[fresh] = @intCast(d + 1);
        const old_count: usize = @intCast(t.counts[b]); const old_keys = t.keys[b];
        t.counts[b] = 0; t.counts[fresh] = 0; t.keys[b] = .{0, 0}; t.keys[fresh] = .{0, 0};
        const bit = @as(usize, 1) << d; const size = @as(usize, 1) << t.gd;
        for (0..size) |i| if (@as(usize, t.directory[i]) == b and i & bit != 0) { t.directory[i] = @intCast(fresh); };
        for (old_keys[0..old_count]) |key| {
            const target: usize = if (@as(usize, key) & bit != 0) fresh else b;
            const count: usize = t.counts[target];
            t.keys[target][count] = key; t.counts[target] += 1;
        }
        t.buckets += 1; return true;
    }
    fn coalesce(t: *Table, start: usize) void {
        var b = start;
        while (t.depths[b] > 1) {
            const d: usize = @intCast(t.depths[b]); const size = @as(usize, 1) << t.gd;
            var rep: ?usize = null;
            for (0..size) |i| if (@as(usize, t.directory[i]) == b) { rep = i; break; };
            if (rep == null) break;
            const prefix = rep.? & ((@as(usize, 1) << d) - 1);
            const buddy_prefix = prefix ^ (@as(usize, 1) << (d - 1));
            const buddy: usize = @intCast(t.directory[buddy_prefix]);
            if (buddy == b or !t.active[buddy] or @as(usize, t.depths[buddy]) != d or t.counts[b] + t.counts[buddy] > 2) break;
            const keep: usize = if (buddy_prefix < prefix) buddy else b;
            const drop: usize = if (keep == b) buddy else b;
            const old_keep: usize = @intCast(t.counts[keep]); const drop_count: usize = @intCast(t.counts[drop]);
            for (0..drop_count) |j| t.keys[keep][old_keep + j] = t.keys[drop][j];
            t.counts[keep] += t.counts[drop]; t.counts[drop] = 0; t.keys[drop] = .{0, 0};
            t.depths[keep] = @intCast(d - 1); t.active[drop] = false;
            for (0..size) |i| if (@as(usize, t.directory[i]) == drop) { t.directory[i] = @intCast(keep); };
            t.buckets -= 1; b = keep;
        }
        while (t.gd > 1) {
            const half = @as(usize, 1) << (t.gd - 1); var mirror = true;
            for (0..half) |i| if (t.directory[i] != t.directory[i + half]) { mirror = false; break; };
            if (!mirror) break;
            t.gd -= 1;
        }
    }
};

fn solve(input: []const i64) i64 {
    if (input.len == 0 or input.len > WORDS or input[0] < 0 or input[0] > @as(i64, OPS)) return -1;
    const q: usize = @intCast(input[0]);
    if (input.len != 1 + 2 * q) return -1;
    for (0..q) |i| if (input[1 + 2 * i] < 0 or input[1 + 2 * i] > 2 or input[2 + 2 * i] < 0 or input[2 + 2 * i] > 255) return -1;
    var t = Table.init(); var success: u64 = 0;
    for (0..q) |i| {
        const op: usize = @intCast(input[1 + 2 * i]); const key: u8 = @intCast(input[2 + 2 * i]);
        var b = t.bucket(@as(usize, key)); const slot = t.find(b, key); var ok: u64 = 0;
        if (op == 0 and slot == null) {
            while (t.counts[b] == 2) { if (!t.split(b)) break; b = t.bucket(@as(usize, key)); }
            if (t.counts[b] < 2) { const count: usize = @intCast(t.counts[b]); t.keys[b][count] = key; t.counts[b] += 1; t.live += 1; ok = 1; }
        } else if (op == 1 and slot != null) {
            const s = slot.?; t.counts[b] -= 1; const last: usize = @intCast(t.counts[b]); t.keys[b][s] = t.keys[b][last]; t.keys[b][last] = 0; t.live -= 1; ok = 1; t.coalesce(b);
        } else if (op == 2) { ok = if (slot != null) 1 else 0; }
        success = (success << 1) | ok;
    }
    return @intCast(success | (@as(u64, @intCast(t.buckets)) << 40) | (@as(u64, @intCast(t.gd)) << 49) |
        (@as(u64, @intCast(t.high)) << 53) | (@as(u64, @intCast(t.live)) << 57));
}

export fn extendible_hashing_trace(input: ?[*]const i64, length: usize) i64 {
    const ptr = input orelse return -1;
    if (length < 1 or length > WORDS) return -1;
    return solve(ptr[0..length]);
}
