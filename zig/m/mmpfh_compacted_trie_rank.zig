const K: usize = 16;
const Q: usize = 16;
const NN: usize = 31;
const OUT: usize = 174;
const Node = struct { bit: i32, left: i32, right: i32, low: u32, high: u32, leaves: usize };

fn build(lo: usize, hi: usize, width: usize, keys: *const [K]u32, nodes: *[NN]Node, used: *usize) usize {
    const id = used.*; used.* += 1;
    if (hi - lo == 1) { nodes[id] = .{ .bit=-1, .left=-1, .right=-1, .low=keys[lo], .high=keys[lo], .leaves=1 }; return id; }
    const diff = keys[lo] ^ keys[hi - 1];
    var bit: usize = 0;
    while (bit < width and ((diff >> @intCast(width - 1 - bit)) & 1) == 0) : (bit += 1) {}
    const shift = width - 1 - bit;
    var split = lo; while (split < hi and ((keys[split] >> @intCast(shift)) & 1) == 0) : (split += 1) {}
    const left = build(lo, split, width, keys, nodes, used);
    const right = build(split, hi, width, keys, nodes, used);
    nodes[id] = .{ .bit=@intCast(bit), .left=@intCast(left), .right=@intCast(right), .low=keys[lo], .high=keys[hi-1], .leaves=nodes[left].leaves+nodes[right].leaves };
    return id;
}
fn rankKey(query: u32, width: usize, nodes: *const [NN]Node) usize {
    var id: usize = 0; var rank: usize = 0;
    while (true) {
        const node = nodes[id];
        if (query < node.low) return rank;
        if (query > node.high) return rank + node.leaves;
        if (node.bit < 0) return rank;
        const shift = width - 1 - @as(usize, @intCast(node.bit));
        if (((query >> @intCast(shift)) & 1) != 0) { rank += nodes[@intCast(node.left)].leaves; id = @intCast(node.right); }
        else id = @intCast(node.left);
    }
}
fn putI64(out: [*]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[pos+b] = @truncate(bits >> @intCast(8*b));
}
export fn mmpfh_compacted_trie_rank(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > 35) return -1;
    const w0=values[0]; const d0=values[1]; const q0=values[2];
    if (w0<1 or w0>16 or d0<1 or d0>16 or q0<1 or q0>16 or length != 3 + @as(usize,@intCast(d0+q0))) return -1;
    const width: usize=@intCast(w0); const d: usize=@intCast(d0); const q: usize=@intCast(q0);
    const limit: u32=@as(u32,1) << @intCast(width);
    var keys=[_]u32{0}**K;
    for (0..d) |i| { const x=values[3+i]; if(x<0 or @as(u64,@intCast(x))>=@as(u64,limit) or (i>0 and x<=values[2+i])) return -1; keys[i]=@intCast(x); }
    for (0..q) |i| { const x=values[3+d+i]; if(x<0 or @as(u64,@intCast(x))>=@as(u64,limit))return -1; }
    var nodes=[_]Node{.{.bit=-1,.left=-1,.right=-1,.low=0,.high=0,.leaves=0}}**NN;
    var node_count:usize=0; _=build(0,d,width,&keys,&nodes,&node_count);
    var staged=[_]i64{0}**OUT;var used:usize=0;
    staged[used]=d0;used+=1;staged[used]=@intCast(node_count);used+=1;staged[used]=q0;used+=1;
    for(0..node_count)|i|{const node=nodes[i];staged[used]=@intCast(node.bit);used+=1;staged[used]=@intCast(node.left);used+=1;staged[used]=@intCast(node.right);used+=1;staged[used]=@intCast(node.low);used+=1;staged[used]=@intCast(node.high);used+=1;}
    for(0..q)|i|{staged[used]=@intCast(rankKey(@intCast(values[3+d+i]),width,&nodes));used+=1;}
    const required=used*8;const out=output orelse return -2;if(capacity<required)return -2;
    for(0..used)|i|putI64(out,i*8,staged[i]);return @intCast(required);
}
