const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_Q: usize = 12;
const MAX_INPUT: usize = 93;

#[derive(Clone, Copy)]
struct Affine { multiplier: i64, addend: i64 }
#[derive(Clone, Copy)]
struct Node {
    child: [i32; 2], parent: i32, reversed: bool,
    value: Affine, forward: Affine, backward: Affine,
}
#[derive(Clone, Copy, Default)]
struct Query { kind: i64, a: i64, b: i64, c: i64, d: i64 }

fn identity() -> Affine { Affine { multiplier: 1, addend: 0 } }
fn compose(after: Affine, before: Affine) -> Affine {
    Affine {
        multiplier: after.multiplier * before.multiplier % MODULUS,
        addend: (after.multiplier * before.addend + after.addend) % MODULUS,
    }
}
fn is_aux_root(nodes: &[Node; MAX_N], x: usize) -> bool {
    let p = nodes[x].parent;
    p < 0 || (nodes[p as usize].child[0] != x as i32 && nodes[p as usize].child[1] != x as i32)
}
fn pull(nodes: &mut [Node; MAX_N], x: usize) {
    let lf = if nodes[x].child[0] < 0 { identity() } else { nodes[nodes[x].child[0] as usize].forward };
    let rf = if nodes[x].child[1] < 0 { identity() } else { nodes[nodes[x].child[1] as usize].forward };
    let lb = if nodes[x].child[0] < 0 { identity() } else { nodes[nodes[x].child[0] as usize].backward };
    let rb = if nodes[x].child[1] < 0 { identity() } else { nodes[nodes[x].child[1] as usize].backward };
    nodes[x].forward = compose(rf, compose(nodes[x].value, lf));
    nodes[x].backward = compose(lb, compose(nodes[x].value, rb));
}
fn reverse_path(nodes: &mut [Node; MAX_N], x: i32) {
    if x < 0 { return; }
    let node = &mut nodes[x as usize];
    node.child.swap(0, 1);
    std::mem::swap(&mut node.forward, &mut node.backward);
    node.reversed = !node.reversed;
}
fn push(nodes: &mut [Node; MAX_N], x: usize) {
    if !nodes[x].reversed { return; }
    let left = nodes[x].child[0]; let right = nodes[x].child[1];
    reverse_path(nodes, left); reverse_path(nodes, right);
    nodes[x].reversed = false;
}
fn rotate(nodes: &mut [Node; MAX_N], x: usize) {
    let p = nodes[x].parent as usize;
    let g = nodes[p].parent;
    let direction = usize::from(nodes[p].child[1] == x as i32);
    let middle = nodes[x].child[direction ^ 1];
    if !is_aux_root(nodes, p) {
        let gi = g as usize;
        let side = usize::from(nodes[gi].child[1] == p as i32);
        nodes[gi].child[side] = x as i32;
    }
    nodes[x].parent = g;
    nodes[x].child[direction ^ 1] = p as i32;
    nodes[p].parent = x as i32;
    nodes[p].child[direction] = middle;
    if middle >= 0 { nodes[middle as usize].parent = p as i32; }
    pull(nodes, p); pull(nodes, x);
}
fn splay(nodes: &mut [Node; MAX_N], x: usize) {
    let mut stack = [0usize; MAX_N];
    let mut count = 1;
    let mut y = x;
    stack[0] = y;
    while !is_aux_root(nodes, y) { y = nodes[y].parent as usize; stack[count] = y; count += 1; }
    while count > 0 { count -= 1; push(nodes, stack[count]); }
    while !is_aux_root(nodes, x) {
        let p = nodes[x].parent as usize;
        if !is_aux_root(nodes, p) {
            let g = nodes[p].parent as usize;
            let zigzig = (nodes[p].child[0] == x as i32) == (nodes[g].child[0] == p as i32);
            rotate(nodes, if zigzig { p } else { x });
        }
        rotate(nodes, x);
    }
}
fn access(nodes: &mut [Node; MAX_N], x: usize) {
    let mut last = -1i32;
    let mut y = x as i32;
    while y >= 0 {
        let yi = y as usize;
        splay(nodes, yi);
        nodes[yi].child[1] = last;
        if last >= 0 { nodes[last as usize].parent = y; }
        pull(nodes, yi);
        last = y;
        y = nodes[yi].parent;
    }
    splay(nodes, x);
}
fn make_root(nodes: &mut [Node; MAX_N], x: usize) { access(nodes, x); reverse_path(nodes, x as i32); }
fn find_root(nodes: &mut [Node; MAX_N], x: usize) -> usize {
    access(nodes, x); push(nodes, x);
    let mut root = x;
    while nodes[root].child[0] >= 0 { root = nodes[root].child[0] as usize; push(nodes, root); }
    splay(nodes, root); root
}
fn link_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> bool {
    if u == v { return false; }
    make_root(nodes, u);
    if find_root(nodes, v) == u { return false; }
    nodes[u].parent = v as i32; true
}
fn cut_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> bool {
    if u == v { return false; }
    make_root(nodes, u); access(nodes, v);
    if nodes[v].child[0] != u as i32 || nodes[u].child[1] >= 0 { return false; }
    nodes[v].child[0] = -1; nodes[u].parent = -1; pull(nodes, v); true
}
fn set_value(nodes: &mut [Node; MAX_N], vertex: usize, value: Affine) {
    access(nodes, vertex); nodes[vertex].value = value; pull(nodes, vertex);
}
fn path_composition(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> Option<Affine> {
    make_root(nodes, u);
    if find_root(nodes, v) != u { return None; }
    make_root(nodes, u); access(nodes, v); Some(nodes[v].forward)
}
fn find_dsu(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item { parent[item] = parent[parent[item]]; item = parent[item]; }
    item
}
fn connected(adjacency: &[bool; MAX_N * MAX_N], n: usize, start: usize, target: usize) -> bool {
    let mut seen = [false; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut top = 1; seen[start] = true; stack[0] = start;
    while top > 0 {
        top -= 1; let u = stack[top];
        if u == target { return true; }
        for v in 0..n {
            if adjacency[u * MAX_N + v] && !seen[v] { seen[v] = true; stack[top] = v; top += 1; }
        }
    }
    false
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_tree_vertex_set_path_composite(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = input[0]; let q_value = input[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize; let q = q_value as usize;
    if length < 2 + 2 * n + 2 * (n - 1) + 4 * q { return -1; }
    let mut values = [identity(); MAX_N];
    for i in 0..n {
        let multiplier = input[2 + 2 * i]; let addend = input[3 + 2 * i];
        if !(1..MODULUS).contains(&multiplier) || !(0..MODULUS).contains(&addend) { return -1; }
        values[i] = Affine { multiplier, addend };
    }
    let mut adjacency = [false; MAX_N * MAX_N];
    let mut dsu = [0usize; MAX_N];
    let mut edge_u = [0usize; MAX_N]; let mut edge_v = [0usize; MAX_N];
    for i in 0..n { dsu[i] = i; }
    let mut cursor = 2 + 2 * n;
    for edge in 0..n - 1 {
        let u_value = input[cursor]; let v_value = input[cursor + 1]; cursor += 2;
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1; }
        let u = u_value as usize; let v = v_value as usize;
        let root_u = find_dsu(&mut dsu, u); let root_v = find_dsu(&mut dsu, v);
        if root_u == root_v { return -1; }
        dsu[root_v] = root_u;
        adjacency[u * MAX_N + v] = true; adjacency[v * MAX_N + u] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    let mut queries = [Query::default(); MAX_Q];
    let mut answer_count = 0;
    for i in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor]; cursor += 1;
        let mut current = Query { kind, a: 0, b: 0, c: 0, d: 0 };
        if kind == 0 {
            if length - cursor < 4 { return -1; }
            current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; current.d=input[cursor+3]; cursor+=4;
            if current.a<0 || current.a>=n_value || current.b<0 || current.b>=n_value || current.c<0 || current.c>=n_value || current.d<0 || current.d>=n_value || current.a==current.b || current.c==current.d { return -1; }
            let u=current.a as usize; let v=current.b as usize; let w=current.c as usize; let x=current.d as usize;
            if !adjacency[u*MAX_N+v] { return -1; }
            adjacency[u*MAX_N+v]=false; adjacency[v*MAX_N+u]=false;
            if connected(&adjacency,n,w,x) { return -1; }
            adjacency[w*MAX_N+x]=true; adjacency[x*MAX_N+w]=true;
        } else if kind == 1 {
            if length - cursor < 3 { return -1; }
            current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; cursor+=3;
            if current.a<0 || current.a>=n_value || current.b<1 || current.b>=MODULUS || current.c<0 || current.c>=MODULUS { return -1; }
        } else if kind == 2 {
            if length - cursor < 3 { return -1; }
            current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; cursor+=3;
            if current.a<0 || current.a>=n_value || current.b<0 || current.b>=n_value || current.c<0 || current.c>=MODULUS { return -1; }
            answer_count+=1;
        } else { return -1; }
        queries[i]=current;
    }
    if cursor != length { return -1; }
    let required = 8 * answer_count;
    if output.is_null() || capacity < required { return -2; }
    let mut nodes = [Node { child: [-1; 2], parent: -1, reversed: false,
        value: identity(), forward: identity(), backward: identity() }; MAX_N];
    for i in 0..n { nodes[i].value=values[i]; nodes[i].forward=values[i]; nodes[i].backward=values[i]; }
    for edge in 0..n-1 { if !link_nodes(&mut nodes,edge_u[edge],edge_v[edge]) { return -1; } }
    let mut answers=[0_i64;MAX_Q]; let mut written=0;
    for current in queries.iter().take(q) {
        if current.kind==0 {
            if !cut_nodes(&mut nodes,current.a as usize,current.b as usize) || !link_nodes(&mut nodes,current.c as usize,current.d as usize) { return -1; }
        } else if current.kind==1 {
            set_value(&mut nodes,current.a as usize,Affine{multiplier:current.b,addend:current.c});
        } else {
            let combined=match path_composition(&mut nodes,current.a as usize,current.b as usize){Some(value)=>value,None=>return -1};
            answers[written]=(combined.multiplier*current.c+combined.addend)%MODULUS; written+=1;
        }
    }
    for i in 0..written { unsafe { store_le(output,8*i,answers[i]); } }
    required as i64
}
