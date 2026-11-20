const std = @import("std");
const MAX_N: usize = 20;
const MAX_M: usize = 32;
const MAX_INPUT: usize = 35;
const MAX_NODES: usize = 128;
const MAX_OUTPUT: usize = 648;
const LEAF: u8 = 0;
const P_NODE: u8 = 1;
const Q_NODE: u8 = 2;
const WHITE: u8 = 0;
const BLACK: u8 = 1;
const MIXED: u8 = 2;

const Node = struct { kind: u8 = LEAF, count: usize = 0, arg: u8 = 0, child: [MAX_N]u8 = @splat(0) };
const Tree = struct {
    nodes: [MAX_NODES]Node = @splat(.{}),
    color: [MAX_NODES]u8 = @splat(0),
    free_id: [MAX_NODES]u8 = @splat(0),
    next_id: usize = 0,
    free_count: usize = 0,
    root: usize = 0,
};

fn newNode(t: *Tree, kind: u8) ?usize {
    var id: usize = 0;
    if (t.free_count != 0) { t.free_count -= 1; id = t.free_id[t.free_count]; }
    else { if (t.next_id >= MAX_NODES) return null; id = t.next_id; t.next_id += 1; }
    t.nodes[id] = .{};
    t.nodes[id].kind = kind;
    return id;
}
fn deleteNode(t: *Tree, id: usize) void { t.nodes[id].count = 0; t.free_id[t.free_count] = @intCast(id); t.free_count += 1; }
fn push(t: *Tree, id: usize, child: usize) void { const at = t.nodes[id].count; t.nodes[id].child[at] = @intCast(child); t.nodes[id].count += 1; }

fn paint(t: *Tree, id: usize, mask: u64) u8 {
    const node = t.nodes[id];
    if (node.kind == LEAF) { t.color[id] = if ((mask >> node.arg) & 1 != 0) BLACK else WHITE; return t.color[id]; }
    var saw_white = false; var saw_black = false;
    for (0..node.count) |i| { const shade = paint(t, @intCast(t.nodes[id].child[i]), mask); saw_white = saw_white or shade != BLACK; saw_black = saw_black or shade != WHITE; }
    t.color[id] = if (saw_white and saw_black) MIXED else if (saw_black) BLACK else WHITE;
    return t.color[id];
}
fn qPattern(t: *const Tree, children: *const [MAX_N]u8, count: usize) bool {
    var pivot: ?usize = null; var mixed: usize = 0;
    for (0..count) |i| { if (t.color[@as(usize, children[i])] == MIXED) { pivot = i; mixed += 1; if (mixed > 1) return false; } }
    if (mixed == 0) { for (0..count) |i| { if (t.color[@as(usize, children[i])] == BLACK) { pivot = i; break; } } }
    if (pivot == null) return false;
    const p = pivot.?;
    for (0..p) |i| { if (t.color[@as(usize, children[i])] != WHITE) return false; }
    for (p + 1..count) |i| { if (t.color[@as(usize, children[i])] != BLACK) return false; }
    return true;
}
fn split(t: *Tree, id: usize, out: *[MAX_N]u8) ?usize {
    const node = t.nodes[id];
    if (t.color[id] != MIXED) { out[0] = @intCast(id); return 1; }
    var old = node.child;
    var white: [MAX_N]u8 = @splat(0); var black: [MAX_N]u8 = @splat(0); var mixed: [MAX_N]u8 = @splat(0);
    var nw: usize = 0; var nb: usize = 0; var nm: usize = 0; var used: usize = 0;
    for (0..node.count) |i| { const child = old[i]; switch (t.color[@as(usize, child)]) { WHITE => { white[nw] = child; nw += 1; }, BLACK => { black[nb] = child; nb += 1; }, else => { mixed[nm] = child; nm += 1; } } }
    if (node.kind == Q_NODE) {
        if (!qPattern(t, &old, node.count)) { std.mem.reverse(u8, old[0..node.count]); if (!qPattern(t, &old, node.count)) return null; }
        for (0..node.count) |i| { const child: usize = @intCast(old[i]); if (t.color[child] == MIXED) { var part: [MAX_N]u8 = @splat(0); const count = split(t, child, &part) orelse return null; for (0..count) |j| { out[used] = part[j]; used += 1; } } else { out[used] = old[i]; used += 1; } }
    } else {
        if (nm > 1) return null;
        if (nw > 0) { const group = newNode(t, P_NODE) orelse return null; for (0..nw) |i| push(t, group, white[i]); out[used] = @intCast(group); used += 1; }
        if (nm > 0) { var part: [MAX_N]u8 = @splat(0); const count = split(t, mixed[0], &part) orelse return null; for (0..count) |i| { out[used] = part[i]; used += 1; } }
        if (nb > 0) { const group = newNode(t, P_NODE) orelse return null; for (0..nb) |i| push(t, group, black[i]); out[used] = @intCast(group); used += 1; }
    }
    deleteNode(t, id);
    return used;
}

fn work(t: *Tree, id: usize) bool {
    const node = t.nodes[id]; if (t.color[id] != MIXED) return true;
    var old: [MAX_N]u8 = @splat(0); var white: [MAX_N]u8 = @splat(0); var black: [MAX_N]u8 = @splat(0); var mixed: [MAX_N]u8 = @splat(0);
    var nw: usize = 0; var nb: usize = 0; var nm: usize = 0;
    for (0..node.count) |i| { old[i] = node.child[i]; switch (t.color[@as(usize, old[i])]) { WHITE => { white[nw] = old[i]; nw += 1; }, BLACK => { black[nb] = old[i]; nb += 1; }, else => { mixed[nm] = old[i]; nm += 1; } } }
    if (node.kind == P_NODE) {
        if (nb == 0 and nm == 1) return work(t, @intCast(mixed[0]));
        if (nm > 2) return false;
        const q = newNode(t, Q_NODE) orelse return false;
        for (0..nw) |i| t.nodes[id].child[i] = white[i];
        t.nodes[id].child[nw] = @intCast(q); t.nodes[id].count = @intCast(nw + 1);
        if (nm > 0) { var part: [MAX_N]u8 = @splat(0); const count = split(t, mixed[0], &part) orelse return false; for (0..count) |i| push(t, q, part[i]); }
        if (nb > 0) { const group = newNode(t, P_NODE) orelse return false; for (0..nb) |i| push(t, group, black[i]); push(t, q, group); }
        if (nm == 2) { var part: [MAX_N]u8 = @splat(0); const count = split(t, mixed[1], &part) orelse return false; var i = count; while (i > 0) { i -= 1; push(t, q, part[i]); } }
        return true;
    }
    var left: ?usize = null; var right: usize = 0;
    for (0..node.count) |i| { if (t.color[@as(usize, old[i])] != WHITE) { if (left == null) left = i; right = i; } }
    if (left == null) return false;
    const l = left.?;
    for (l + 1..right) |i| { if (t.color[@as(usize, old[i])] != BLACK) return false; }
    if (l == right and t.color[@as(usize, old[l])] == MIXED) return work(t, @intCast(old[l]));
    var result: [MAX_N]u8 = @splat(0); var used: usize = 0;
    for (0..l) |i| { result[used] = old[i]; used += 1; }
    var part: [MAX_N]u8 = @splat(0); var count = split(t, old[l], &part) orelse return false;
    for (0..count) |i| { result[used] = part[i]; used += 1; }
    for (l + 1..right) |i| { result[used] = old[i]; used += 1; }
    if (right != l) { count = split(t, old[right], &part) orelse return false; var i = count; while (i > 0) { i -= 1; result[used] = part[i]; used += 1; } }
    for (right + 1..node.count) |i| { result[used] = old[i]; used += 1; }
    t.nodes[id].count = @intCast(used); @memcpy(t.nodes[id].child[0..used], result[0..used]); return true;
}

fn normalize(t: *Tree, id: usize) usize {
    const node = t.nodes[id]; if (node.kind == LEAF) return id;
    for (0..node.count) |i| t.nodes[id].child[i] = @intCast(normalize(t, @intCast(node.child[i])));
    if (t.nodes[id].count == 1) { const child: usize = @intCast(t.nodes[id].child[0]); deleteNode(t, id); return child; }
    if (t.nodes[id].kind == Q_NODE and t.nodes[id].count == 2) t.nodes[id].kind = P_NODE;
    return id;
}
fn compare(t: *const Tree, a: usize, b: usize) i32 {
    const x = t.nodes[a]; const y = t.nodes[b]; const xa: u8 = if (x.kind == LEAF) x.arg else x.count; const ya: u8 = if (y.kind == LEAF) y.arg else y.count;
    if (x.kind != y.kind) return if (x.kind < y.kind) -1 else 1;
    if (xa != ya) return if (xa < ya) -1 else 1;
    if (x.kind != LEAF) { for (0..x.count) |i| { const c = compare(t, @intCast(x.child[i]), @intCast(y.child[i])); if (c != 0) return c; } }
    return 0;
}
fn canonicalize(t: *Tree, id: usize) void {
    const node = t.nodes[id]; if (node.kind == LEAF) return;
    for (0..node.count) |i| canonicalize(t, @intCast(node.child[i]));
    if (node.kind == P_NODE) { for (1..node.count) |i| { const item = t.nodes[id].child[i]; var j = i; while (j > 0 and compare(t, item, t.nodes[id].child[j - 1]) < 0) { t.nodes[id].child[j] = t.nodes[id].child[j - 1]; j -= 1; } t.nodes[id].child[j] = item; } }
    else { var order: i32 = 0; for (0..node.count) |i| { order = compare(t, node.child[i], node.child[node.count - 1 - i]); if (order != 0) break; } if (order > 0) std.mem.reverse(u8, t.nodes[id].child[0..node.count]); }
}
fn frontierCount(t: *const Tree, id: usize) i64 { const node=t.nodes[id];if(node.kind==LEAF)return 1;var result:i64=1;for(0..node.count)|i|result*=frontierCount(t,@intCast(node.child[i]));if(node.kind==P_NODE){for(2..node.count+1)|i|result*=@intCast(i);}else result*=2;return result; }
fn nodeCount(t:*const Tree,id:usize)usize{const node=t.nodes[id];var count:usize=1;if(node.kind!=LEAF){for(0..node.count)|i|count+=nodeCount(t,@intCast(node.child[i]));}return count;}
fn serialize(t:*const Tree,id:usize,words:*[81]i64,used:*usize)void{const node=t.nodes[id];words[used.*]=node.kind;used.*+=1;words[used.*]=if(node.kind==LEAF)node.arg else @intCast(node.count);used.*+=1;if(node.kind!=LEAF){for(0..node.count)|i|serialize(t,@intCast(node.child[i]),words,used);}}
fn storeI64(out:*[MAX_OUTPUT]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|i|out[offset+i]=@truncate(bits>>@intCast(i*8));}

export fn pq_tree_consecutive_ones(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if(input_opt==null||length<2||length>MAX_INPUT)return -1;const input=input_opt.?;const n_raw=input[0];const m_raw=input[1];if(n_raw<2||n_raw>MAX_N||m_raw<0||m_raw>MAX_M||length!=2+@as(usize,@intCast(m_raw)))return -1;
    const n:usize=@intCast(n_raw);const m:usize=@intCast(m_raw);const valid=(@as(u64,1)<<@intCast(n))-1;for(0..m)|r|{const mask=input[2+r];if(mask<0||(@as(u64,@intCast(mask))&~valid)!=0)return -1;}
    var tree=Tree{};tree.next_id=n+1;tree.root=n;for(0..n)|i|{tree.nodes[i].kind=LEAF;tree.nodes[i].arg=@intCast(i);}tree.nodes[n].kind=P_NODE;tree.nodes[n].count=@intCast(n);for(0..n)|i|tree.nodes[n].child[i]=@intCast(i);
    for(0..m)|r|{_ = paint(&tree,tree.root,@intCast(input[2+r]));if(!work(&tree,tree.root)){var staged:[MAX_OUTPUT]u8=@splat(0);if(output_opt==null||capacity<24)return -2;for(0..24)|i|output_opt.?[i]=staged[i];return 24;}tree.root=normalize(&tree,tree.root);}
    canonicalize(&tree,tree.root);var words:[81]i64=@splat(0);var used:usize=0;words[used]=1;used+=1;words[used]=frontierCount(&tree,tree.root);used+=1;words[used]=@intCast(nodeCount(&tree,tree.root));used+=1;serialize(&tree,tree.root,&words,&used);var staged:[MAX_OUTPUT]u8=@splat(0);for(0..used)|i|storeI64(&staged,i*8,words[i]);const bytes=used*8;if(output_opt==null||capacity<bytes)return -2;for(0..bytes)|i|output_opt.?[i]=staged[i];return @intCast(bytes);
}
