const MAX_OPS: usize = 128;
const MAX_NODES: usize = MAX_OPS + 1;
const Node = struct { key: i32, priority: i64, left: usize, right: usize };
const EMPTY = Node{ .key = 0, .priority = 0, .left = 0, .right = 0 };
fn priorityFor(key: i32) i64 { return @rem((@as(i64, key) + 1_000_000) * 1_103_515_245 + 12_345, 2_147_483_648); }
fn contains(nodes: []const Node, root: usize, key: i32) bool {
    if (root == 0) return false;
    if (key == nodes[root].key) return true;
    return contains(nodes, if (key < nodes[root].key) nodes[root].left else nodes[root].right, key);
}
fn rotateRight(nodes: []Node, root: usize) usize { const p=nodes[root].left;nodes[root].left=nodes[p].right;nodes[p].right=root;return p; }
fn rotateLeft(nodes: []Node, root: usize) usize { const p=nodes[root].right;nodes[root].right=nodes[p].left;nodes[p].left=root;return p; }
fn insertNode(nodes: []Node, next: *usize, root: usize, key: i32) usize {
    if (root == 0) { const id=next.*;next.*+=1;nodes[id]=.{.key=key,.priority=priorityFor(key),.left=0,.right=0};return id; }
    if (key == nodes[root].key) return root;
    if (key < nodes[root].key) { const child=insertNode(nodes,next,nodes[root].left,key);nodes[root].left=child;if(nodes[child].priority>nodes[root].priority)return rotateRight(nodes,root); }
    else { const child=insertNode(nodes,next,nodes[root].right,key);nodes[root].right=child;if(nodes[child].priority>nodes[root].priority)return rotateLeft(nodes,root); }
    return root;
}
fn merge(nodes: []Node, left: usize, right: usize) usize {
    if (left == 0) return right;if (right == 0) return left;
    if (nodes[left].priority > nodes[right].priority) { nodes[left].right=merge(nodes,nodes[left].right,right);return left; }
    nodes[right].left=merge(nodes,left,nodes[right].left);return right;
}
fn eraseNode(nodes: []Node, root: usize, key: i32) usize {
    if (key < nodes[root].key) { nodes[root].left=eraseNode(nodes,nodes[root].left,key);return root; }
    if (key > nodes[root].key) { nodes[root].right=eraseNode(nodes,nodes[root].right,key);return root; }
    return merge(nodes,nodes[root].left,nodes[root].right);
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void { const bits: u64=@bitCast(value);for(0..8)|b|output[offset+b]=@truncate(bits>>@intCast(8*b)); }

pub export fn treap_unique_key_set(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or input[0] < 0 or input[0] > MAX_OPS or length != 1 + 2 * @as(usize, @intCast(input[0]))) return -1;
    const ops: usize=@intCast(input[0]);
    for(0..ops)|i|{const op=input[1+2*i];const key=input[2+2*i];if((op!=0 and op!=1) or key < -1_000_000 or key > 1_000_000)return -1;}
    var nodes=[_]Node{EMPTY}**MAX_NODES;var next:usize=1;var root:usize=0;
    for(0..ops)|i|{const op=input[1+2*i];const key:i32=@intCast(input[2+2*i]);const present=contains(nodes[0..],root,key);if((op==0 and present) or (op==1 and !present))return -1;root=if(op==0)insertNode(nodes[0..],&next,root,key) else eraseNode(nodes[0..],root,key);}
    var stack=[_]usize{0}**MAX_OPS;var sorted=[_]i64{0}**MAX_OPS;var top:usize=0;var current=root;var count:usize=0;
    while(current!=0 or top>0){while(current!=0){stack[top]=current;top+=1;current=nodes[current].left;}top-=1;current=stack[top];sorted[count]=nodes[current].key;count+=1;current=nodes[current].right;}
    const required=count*8;if(output==null or capacity<required)return -2;for(0..count)|i|putI64(output,8*i,sorted[i]);return @intCast(count);
}
