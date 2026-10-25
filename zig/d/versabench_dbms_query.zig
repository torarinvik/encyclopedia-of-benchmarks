const MAX_NODES: usize = 7;
const MAX_ENTRIES: usize = 4;
const MAX_RECORDS: usize = 16;
const Entry = struct { lo: [4]i64, hi: [4]i64, reference: i64 };
const Node = struct { level: i64, count: usize, entries: [MAX_ENTRIES]Entry };

fn validBox(lo: [4]i64, hi: [4]i64) bool {
    for (0..4) |d| if (lo[d] < -8 or lo[d] > 8 or hi[d] < -8 or hi[d] > 8 or lo[d] >= hi[d]) return false;
    return true;
}
fn intersects(e: Entry, lo: [4]i64, hi: [4]i64) bool {
    for (0..4) |d| if (lo[d] > e.hi[d] or e.lo[d] > hi[d]) return false;
    return true;
}
fn writeI64(out: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[word*8+b] = @truncate(bits >> @intCast(8*b));
}

export fn versabench_dbms_query(raw: ?[*]const i64, length: usize, raw_output: ?[*]u8, output_capacity: usize) i64 {
    if (raw == null or length < 10 or length > 277) return -1;
    const v = raw.?[0..length];
    const nn = v[0]; const rootv = v[1];
    if (nn < 1 or nn > @as(i64, MAX_NODES) or rootv < 0 or rootv >= nn) return -1;
    const n: usize = @intCast(nn); const root: usize = @intCast(rootv);
    var qlo: [4]i64 = undefined; var qhi: [4]i64 = undefined;
    for (0..4) |d| { qlo[d] = v[2+d]; qhi[d] = v[6+d]; }
    if (!validBox(qlo, qhi)) return -1;
    var nodes: [MAX_NODES]Node = undefined;
    var parents: [MAX_NODES]usize = @splat(0);
    var seen: [32]bool = @splat(false);
    var leaf_total: usize = 0; var pos: usize = 10;
    for (0..n) |ni| {
        if (pos+2 > length) return -1;
        const level = v[pos]; const countv = v[pos+1]; pos += 2;
        if (level < 0 or level > 2 or countv < 1 or countv > @as(i64, MAX_ENTRIES) or pos + @as(usize, @intCast(countv))*9 > length) return -1;
        const count: usize = @intCast(countv);
        nodes[ni].level = level; nodes[ni].count = count;
        for (0..count) |ei| {
            var lo: [4]i64 = undefined; var hi: [4]i64 = undefined;
            for (0..4) |d| { lo[d] = v[pos+d]; } pos += 4;
            for (0..4) |d| { hi[d] = v[pos+d]; } pos += 4;
            const reference = v[pos]; pos += 1;
            if (!validBox(lo, hi)) return -1;
            nodes[ni].entries[ei] = .{ .lo=lo, .hi=hi, .reference=reference };
            if (level == 0) {
                if (reference < 0 or reference >= 32) return -1;
                const id: usize = @intCast(reference);
                if (seen[id] or leaf_total >= MAX_RECORDS) return -1;
                seen[id] = true; leaf_total += 1;
            } else {
                if (reference < 0 or reference >= nn) return -1;
                const child_id: usize = @intCast(reference);
                parents[child_id] += 1;
                if (parents[child_id] > 1) return -1;
            }
        }
    }
    if (pos != length or parents[root] != 0) return -1;
    for (0..n) |ni| {
        if (ni != root and parents[ni] != 1) return -1;
        if (nodes[ni].level == 0) continue;
        for (0..nodes[ni].count) |ei| {
            const branch = nodes[ni].entries[ei];
            const child: *const Node = &nodes[@intCast(branch.reference)];
            if (child.level != nodes[ni].level - 1) return -1;
            for (0..child.count) |ce| {
                for (0..4) |d| {
                    if (branch.lo[d] > child.entries[ce].lo[d] or branch.hi[d] < child.entries[ce].hi[d]) return -1;
                }
            }
        }
    }
    var stack: [MAX_NODES]usize = undefined; var top: usize = 1; stack[0] = root;
    var hits: [MAX_RECORDS]i64 = undefined; var hit_count: usize = 0;
    while (top > 0) {
        top -= 1; const ni = stack[top]; const node = nodes[ni];
        if (node.level == 0) {
            for (0..node.count) |ei| { const e=node.entries[ei]; if (intersects(e,qlo,qhi)) { hits[hit_count]=e.reference;hit_count+=1; } }
        } else {
            var rev=node.count; while (rev>0) { rev-=1; const e=node.entries[rev]; if (intersects(e,qlo,qhi)) { stack[top]=@intCast(e.reference);top+=1; } }
        }
    }
    const bytes=hit_count*8;
    if (raw_output == null or output_capacity < bytes) return -2;
    const output=raw_output.?;
    for (0..hit_count) |i| writeI64(output,i,hits[i]);
    return @intCast(bytes);
}
