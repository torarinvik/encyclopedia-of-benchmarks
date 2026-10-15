const MAX_OPS: usize = 32;
const POOL_CAP: usize = 8192;
const OUT_CAP: usize = 5000;
const Node = struct { value: i32, left: usize, right: usize, height: i32 };
const EMPTY = Node{ .value = 0, .left = 0, .right = 0, .height = -1 };

fn nodeHeight(pool: []const Node, id: usize) i32 { return if (id == 0) -1 else pool[id].height; }
fn makeNode(pool: []Node, next: *usize, value: i32, left: usize, right: usize) usize {
    const id = next.*; next.* += 1;
    const lh = nodeHeight(pool, left); const rh = nodeHeight(pool, right);
    pool[id] = .{ .value = value, .left = left, .right = right, .height = 1 + @max(lh, rh) };
    return id;
}
fn balance(pool: []const Node, id: usize) i32 { return nodeHeight(pool, pool[id].right) - nodeHeight(pool, pool[id].left); }
fn rotateRight(pool: []Node, next: *usize, root: usize) usize {
    const n = pool[root]; const left = pool[n.left];
    const moved = makeNode(pool, next, n.value, left.right, n.right);
    return makeNode(pool, next, left.value, left.left, moved);
}
fn rotateLeft(pool: []Node, next: *usize, root: usize) usize {
    const n = pool[root]; const right = pool[n.right];
    const moved = makeNode(pool, next, n.value, n.left, right.left);
    return makeNode(pool, next, right.value, moved, right.right);
}
fn rebalance(pool: []Node, next: *usize, root: usize) usize {
    const bf = balance(pool, root); const n = pool[root];
    if (bf > 1) {
        if (balance(pool, n.right) < 0) { const rotated = rotateRight(pool, next, n.right); const nr = makeNode(pool, next, n.value, n.left, rotated); return rotateLeft(pool, next, nr); }
        return rotateLeft(pool, next, root);
    }
    if (bf < -1) {
        if (balance(pool, n.left) > 0) { const rotated = rotateLeft(pool, next, n.left); const nr = makeNode(pool, next, n.value, rotated, n.right); return rotateRight(pool, next, nr); }
        return rotateRight(pool, next, root);
    }
    return root;
}
fn insertNode(pool: []Node, next: *usize, root: usize, value: i32) usize {
    if (root == 0) return makeNode(pool, next, value, 0, 0);
    const n = pool[root]; if (value == n.value) return root;
    if (value < n.value) { const left = insertNode(pool, next, n.left, value); return rebalance(pool, next, makeNode(pool, next, n.value, left, n.right)); }
    const right = insertNode(pool, next, n.right, value); return rebalance(pool, next, makeNode(pool, next, n.value, n.left, right));
}
fn deleteMin(pool: []Node, next: *usize, root: usize, minimum: *i32) usize {
    const n = pool[root]; if (n.left == 0) { minimum.* = n.value; return n.right; }
    const left = deleteMin(pool, next, n.left, minimum); return rebalance(pool, next, makeNode(pool, next, n.value, left, n.right));
}
fn deleteNode(pool: []Node, next: *usize, root: usize, value: i32) usize {
    if (root == 0) return 0;
    const n = pool[root];
    if (value < n.value) { const left = deleteNode(pool, next, n.left, value); return rebalance(pool, next, makeNode(pool, next, n.value, left, n.right)); }
    if (value > n.value) { const right = deleteNode(pool, next, n.right, value); return rebalance(pool, next, makeNode(pool, next, n.value, n.left, right)); }
    if (n.left == 0) return n.right;
    if (n.right == 0) return n.left;
    var successor: i32 = 0; const right = deleteMin(pool, next, n.right, &successor);
    return rebalance(pool, next, makeNode(pool, next, successor, n.left, right));
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value); for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn avltree_persistent_insert_delete(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or input[0] < 0 or input[0] > MAX_OPS or length != 1 + 3 * @as(usize, @intCast(input[0]))) return -1;
    const ops: usize = @intCast(input[0]);
    for (0..ops) |i| { const parent=input[1+3*i];const op=input[2+3*i];const value=input[3+3*i];if(parent<0 or parent>=@as(i64,@intCast(i+1)) or (op!=0 and op!=1) or value< -1000 or value>1000)return -1; }
    var pool = [_]Node{EMPTY} ** POOL_CAP; var next: usize = 1; var roots = [_]usize{0} ** (MAX_OPS + 1);
    for (0..ops) |i| { const root=roots[@intCast(input[1+3*i])];roots[i+1]=if(input[2+3*i]==0)insertNode(pool[0..],&next,root,@intCast(input[3+3*i])) else deleteNode(pool[0..],&next,root,@intCast(input[3+3*i]));if(next>=POOL_CAP-64)return -1; }
    var packed=[_]i64{0}**OUT_CAP;var used:usize=0;packed[used]=@intCast(ops+1);used+=1;
    for(0..ops+1)|version|{
        const root=roots[version];var queue=[_]usize{0}**(MAX_OPS+1);var local=[_]i32{-1}**POOL_CAP;var left_ids=[_]i32{-1}**(MAX_OPS+1);var right_ids=[_]i32{-1}**(MAX_OPS+1);var tail:usize=0;
        if(root!=0){queue[0]=root;local[root]=0;tail=1;}
        for(0..tail)|head|{const n=pool[queue[head]];const children=[_]usize{n.left,n.right};for(0..2)|side|{const child=children[side];if(child!=0){if(local[child]<0){local[child]=@intCast(tail);queue[tail]=child;tail+=1;}if(side==0){left_ids[head]=local[child];}else{right_ids[head]=local[child];}}}}
        packed[used]=@intCast(tail);used+=1;packed[used]=nodeHeight(pool[0..],root);used+=1;
        for(0..tail)|i|{const n=pool[queue[i]];packed[used]=n.value;packed[used+1]=n.height;packed[used+2]=left_ids[i];packed[used+3]=right_ids[i];used+=4;}
    }
    const required=used*8;if(output==null or capacity<required)return -2;for(0..used)|i|putI64(output,8*i,packed[i]);return @intCast(required);
}
