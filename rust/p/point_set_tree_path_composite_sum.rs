use core::ffi::c_uchar;

const N: usize = 16;
const Q: usize = 32;
const E: usize = 15;
const K: usize = 75;
const INPUT_MAX: usize = 238;
const MOD: i64 = 998_244_353;
const VERTEX: i16 = 0;
const EDGE: i16 = 1;
const RAKE: i16 = 2;
const BRANCH: i16 = 3;
const ATTACH: i16 = 4;
const COMPRESS: i16 = 5;

#[derive(Clone, Copy, Default)]
struct Affine { mul: i64, add: i64 }

#[derive(Clone, Copy, Default)]
struct Node {
    kind: i16, a: i16, b: i16, parent: i16, shared: i16,
    boundary0: i16, boundary1: i16, boundary_count: i16, edge: i16,
    has0: bool, has1: bool, mask: u16, count: i32, sum0: i64, sum1: i64,
    forward: Affine, reverse: Affine,
}

#[derive(Clone, Copy, Default)]
struct Context { sums: [i64; 2], counts: [i64; 2] }

fn norm(x: i64) -> i64 { let y = x % MOD; if y < 0 { y + MOD } else { y } }
fn identity() -> Affine { Affine { mul: 1, add: 0 } }
fn compose(outer: Affine, inner: Affine) -> Affine {
    Affine { mul: outer.mul * inner.mul % MOD,
             add: (outer.mul * inner.add + outer.add) % MOD }
}
fn apply(map: Affine, sum: i64, count: i64) -> i64 {
    (map.mul * sum + map.add * count) % MOD
}
fn boundary_index(node: &Node, vertex: i16) -> i16 {
    if node.boundary0 == vertex { 0 }
    else if node.boundary_count == 2 && node.boundary1 == vertex { 1 }
    else { -1 }
}
fn has(node: &Node, vertex: i16) -> bool {
    match boundary_index(node, vertex) { 0 => node.has0, 1 => node.has1, _ => false }
}
fn sum_at(node: &Node, vertex: i16) -> i64 {
    if boundary_index(node, vertex) == 0 { node.sum0 } else { node.sum1 }
}
fn map_at(node: &Node, from: i16, to: i16) -> Affine {
    if from == to || node.boundary_count != 2 { identity() }
    else if node.boundary0 == from && node.boundary1 == to { node.forward }
    else { node.reverse }
}

fn recalc(nodes: &mut [Node; K], id: usize, values: &[i64; N], edges: &[Affine; E]) {
    let x = nodes[id];
    if x.kind == VERTEX {
        nodes[id].count = 1;
        nodes[id].mask = 1u16 << (x.boundary0 as u16);
        nodes[id].sum0 = values[x.boundary0 as usize];
        nodes[id].has0 = true;
        return;
    }
    if x.kind == EDGE {
        let map = edges[x.edge as usize];
        nodes[id].forward = map; nodes[id].reverse = map;
        return;
    }
    let a = nodes[x.a as usize];
    let b = nodes[x.b as usize];
    let overlap = has(&a, x.shared) && has(&b, x.shared);
    let removed = if overlap { 1 } else { 0 };
    let duplicate = if overlap { values[x.shared as usize] } else { 0 };
    nodes[id].count = a.count + b.count - removed;
    nodes[id].mask = a.mask | b.mask;
    for index in 0..x.boundary_count as usize {
        let boundary = if index == 0 { x.boundary0 } else { x.boundary1 };
        let total = if boundary == x.shared {
            norm(sum_at(&a, x.shared) + sum_at(&b, x.shared) - duplicate)
        } else if boundary_index(&a, boundary) >= 0 {
            let sibling = norm(sum_at(&b, x.shared) - duplicate);
            (sum_at(&a, boundary) + apply(map_at(&a, boundary, x.shared), sibling,
                (b.count - removed) as i64)) % MOD
        } else {
            let sibling = norm(sum_at(&a, x.shared) - duplicate);
            (sum_at(&b, boundary) + apply(map_at(&b, boundary, x.shared), sibling,
                (a.count - removed) as i64)) % MOD
        };
        let boundary_has = has(&a, boundary) || has(&b, boundary);
        if index == 0 { nodes[id].sum0 = total; nodes[id].has0 = boundary_has; }
        else { nodes[id].sum1 = total; nodes[id].has1 = boundary_has; }
    }
    if x.boundary_count == 2 {
        let (u, v) = (x.boundary0, x.boundary1);
        let (a_u, a_v) = (boundary_index(&a, u) >= 0, boundary_index(&a, v) >= 0);
        let (b_u, b_v) = (boundary_index(&b, u) >= 0, boundary_index(&b, v) >= 0);
        let (forward, reverse) = if a_u && a_v {
            (map_at(&a, u, v), map_at(&a, v, u))
        } else if b_u && b_v {
            (map_at(&b, u, v), map_at(&b, v, u))
        } else {
            (compose(map_at(&a, u, x.shared), map_at(&b, x.shared, v)),
             compose(map_at(&b, v, x.shared), map_at(&a, x.shared, u)))
        };
        nodes[id].forward = forward; nodes[id].reverse = reverse;
    }
}

fn append(nodes: &mut [Node; K], used: &mut usize, kind: i16, a_id: i16, b_id: i16,
          shared: i16, values: &[i64; N], edges: &[Affine; E]) -> i16 {
    if *used >= K { return -1; }
    let id = *used; *used += 1;
    let mut node = Node { kind, a: a_id, b: b_id, parent: -1, shared,
        edge: -1, forward: identity(), reverse: identity(), ..Node::default() };
    if kind == VERTEX { node.boundary0 = shared; node.boundary_count = 1; }
    else if kind == EDGE {
        node.boundary0 = a_id; node.boundary1 = b_id; node.boundary_count = 2; node.edge = shared;
    } else {
        let a = nodes[a_id as usize]; let b = nodes[b_id as usize];
        let ao = if a.boundary_count == 2 && a.boundary0 == shared { a.boundary1 } else { a.boundary0 };
        let bo = if b.boundary_count == 2 && b.boundary0 == shared { b.boundary1 } else { b.boundary0 };
        match kind {
            RAKE => { node.boundary0 = shared; node.boundary_count = 1; }
            BRANCH => { node.boundary0 = ao; node.boundary_count = 1; }
            ATTACH => { node.boundary0 = a.boundary0; node.boundary1 = a.boundary1; node.boundary_count = 2; }
            _ => { node.boundary0 = ao; node.boundary1 = bo; node.boundary_count = 2; }
        }
        nodes[a_id as usize].parent = id as i16;
        nodes[b_id as usize].parent = id as i16;
    }
    nodes[id] = node;
    recalc(nodes, id, values, edges);
    id as i16
}

fn make_rake(nodes: &mut [Node; K], used: &mut usize, base: i16,
             branches: &[i16; N], branch_count: usize, values: &[i64; N], edges: &[Affine; E]) -> i16 {
    let mut level = [-1i16; N + 1]; let mut next = [-1i16; N + 1];
    let mut len = 1; level[0] = base;
    for i in 0..branch_count { level[len] = branches[i]; len += 1; }
    while len > 1 {
        let mut next_len = 0; let mut i = 0;
        while i < len {
            if i + 1 == len { next[next_len] = level[i]; next_len += 1; }
            else {
                let shared = nodes[level[i] as usize].boundary0;
                let id = append(nodes, used, RAKE, level[i], level[i + 1], shared, values, edges);
                if id < 0 { return -1; }
                next[next_len] = id; next_len += 1;
            }
            i += 2;
        }
        level[..next_len].copy_from_slice(&next[..next_len]); len = next_len;
    }
    level[0]
}

fn neighbor_count(adj: &[[bool; N]; N], active: &[bool; N], n: usize, v: usize,
                  out: &mut [usize; 2]) -> usize {
    let mut count = 0;
    for u in 0..n { if active[u] && adj[v][u] { if count < 2 { out[count] = u; } count += 1; } }
    count
}
fn find(parent: &mut [usize; N], mut v: usize) -> usize {
    while parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v]; }
    v
}
fn context_at(node: &Node, ctx: Context, vertex: i16) -> (i64, i64) {
    let i = boundary_index(node, vertex);
    if i == 0 { (ctx.sums[0], ctx.counts[0]) }
    else if i == 1 { (ctx.sums[1], ctx.counts[1]) }
    else { (0, 0) }
}
fn child_context(nodes: &[Node; K], parent_id: usize, child_id: usize,
                 ctx: Context, values: &[i64; N]) -> Context {
    let p = nodes[parent_id]; let child = nodes[child_id];
    let sibling_id = if child_id as i16 == p.a { p.b } else { p.a };
    let sibling = nodes[sibling_id as usize]; let shared = p.shared;
    let overlap = has(&child, shared) && has(&sibling, shared);
    let removed = if overlap { 1 } else { 0 };
    let mut sum_shared = norm(sum_at(&sibling, shared) - if overlap { values[shared as usize] } else { 0 });
    let mut count_shared = sibling.count as i64 - removed;
    for index in 0..sibling.boundary_count as usize {
        let boundary = if index == 0 { sibling.boundary0 } else { sibling.boundary1 };
        if boundary_index(&p, boundary) < 0 { continue; }
        let (outside_sum, outside_count) = context_at(&p, ctx, boundary);
        sum_shared = (sum_shared + apply(map_at(&sibling, shared, boundary), outside_sum, outside_count)) % MOD;
        count_shared += outside_count;
    }
    let mut result = Context::default();
    for i in 0..child.boundary_count as usize {
        let boundary = if i == 0 { child.boundary0 } else { child.boundary1 };
        let (mut sum, mut count) = if boundary == shared {
            (sum_shared, count_shared)
        } else {
            (apply(map_at(&child, boundary, shared), sum_shared, count_shared), count_shared)
        };
        if boundary != shared && boundary_index(&p, boundary) >= 0 {
            let (outside_sum, outside_count) = context_at(&p, ctx, boundary);
            sum = (sum + outside_sum) % MOD; count += outside_count;
        }
        result.sums[i] = sum; result.counts[i] = count;
    }
    result
}
fn query(nodes: &[Node; K], root: usize, vertex_leaf: &[i16; N], vertex: usize,
          values: &[i64; N]) -> i64 {
    let mut path = [0usize; K]; let mut len = 1; path[0] = vertex_leaf[vertex] as usize;
    while path[len - 1] != root && len < K {
        let parent = nodes[path[len - 1]].parent;
        if parent < 0 { return -1; }
        path[len] = parent as usize; len += 1;
    }
    if path[len - 1] != root { return -1; }
    let mut ctx = Context::default();
    for i in (1..len).rev() { ctx = child_context(nodes, path[i], path[i - 1], ctx, values); }
    (nodes[vertex_leaf[vertex] as usize].sum0 + ctx.sums[0]) % MOD
}
fn store(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for i in 0..8 { unsafe { *output.add(offset + i) = (bits >> (8 * i)) as u8; } }
}
#[no_mangle]
pub unsafe extern "C" fn point_set_tree_path_composite_sum(
    input: *const i64, length: usize, output: *mut c_uchar, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT_MAX { return -1; }
    let words = core::slice::from_raw_parts(input, length);
    let nr = words[0]; let qr = words[1];
    if nr < 1 || nr > N as i64 || qr < 1 || qr > Q as i64 { return -1; }
    let n = nr as usize; let q = qr as usize; let mut cursor = 2;
    let mut values = [0i64; N];
    for value in values.iter_mut().take(n) {
        if cursor >= length { return -1; }
        *value = words[cursor]; cursor += 1;
        if *value < 0 || *value >= MOD { return -1; }
    }
    let mut edge_u = [0usize; E]; let mut edge_v = [0usize; E]; let mut edge_map = [Affine::default(); E];
    let mut dsu = [0usize; N]; for i in 0..n { dsu[i] = i; }
    for e in 0..n - 1 {
        if cursor + 4 > length { return -1; }
        let ur = words[cursor]; let vr = words[cursor + 1]; let mul = words[cursor + 2]; let add = words[cursor + 3]; cursor += 4;
        if ur < 0 || ur >= nr || vr < 0 || vr >= nr || ur == vr || mul < 1 || mul >= MOD || add < 0 || add >= MOD { return -1; }
        let u = ur as usize; let v = vr as usize; let ru = find(&mut dsu, u); let rv = find(&mut dsu, v);
        if ru == rv { return -1; }
        dsu[ru] = rv; edge_u[e] = u; edge_v[e] = v; edge_map[e] = Affine { mul, add };
    }
    let tree_root = find(&mut dsu, 0); for v in 1..n { if find(&mut dsu, v) != tree_root { return -1; } }
    let mut op_code = [0i16; Q]; let mut op_item = [0usize; Q]; let mut op_first = [0i64; Q];
    let mut op_second = [0i64; Q]; let mut op_root = [0usize; Q];
    for i in 0..q {
        if cursor >= length { return -1; }
        let opcode = words[cursor]; cursor += 1;
        if opcode == 0 {
            if cursor + 3 > length { return -1; }
            let item = words[cursor]; let value = words[cursor + 1]; let root = words[cursor + 2]; cursor += 3;
            if item < 0 || item >= nr || value < 0 || value >= MOD || root < 0 || root >= nr { return -1; }
            op_code[i] = 0; op_item[i] = item as usize; op_first[i] = value; op_second[i] = 0; op_root[i] = root as usize;
        } else if opcode == 1 {
            if cursor + 4 > length { return -1; }
            let item = words[cursor]; let mul = words[cursor + 1]; let add = words[cursor + 2]; let root = words[cursor + 3]; cursor += 4;
            if item < 0 || item >= nr - 1 || mul < 1 || mul >= MOD || add < 0 || add >= MOD || root < 0 || root >= nr { return -1; }
            op_code[i] = 1; op_item[i] = item as usize; op_first[i] = mul; op_second[i] = add; op_root[i] = root as usize;
        } else { return -1; }
    }
    if cursor != length { return -1; }
    let required = 8 * q;
    if output.is_null() || capacity < required { return -2; }
    let mut nodes = [Node::default(); K]; let mut used = 0usize;
    let mut vertex_leaf = [-1i16; N]; let mut edge_leaf = [-1i16; E];
    for v in 0..n {
        let id = append(&mut nodes, &mut used, VERTEX, -1, -1, v as i16, &values, &edge_map);
        if id < 0 { return -1; } vertex_leaf[v] = id;
    }
    let mut adj = [[false; N]; N]; let mut edge_cluster = [[-1i16; N]; N];
    for e in 0..n - 1 {
        let id = append(&mut nodes, &mut used, EDGE, edge_u[e] as i16, edge_v[e] as i16, e as i16, &values, &edge_map);
        if id < 0 { return -1; } edge_leaf[e] = id;
        adj[edge_u[e]][edge_v[e]] = true; adj[edge_v[e]][edge_u[e]] = true;
        edge_cluster[edge_u[e]][edge_v[e]] = id; edge_cluster[edge_v[e]][edge_u[e]] = id;
    }
    let mut active = [false; N]; for v in 0..n { active[v] = true; }
    let mut branches = [[-1i16; N]; N]; let mut branch_count = [0usize; N]; let mut active_count = n;
    while active_count > 1 {
        if active_count == 2 {
            let mut pair = [0usize; 2]; let mut found = 0;
            for v in 0..n { if active[v] { pair[found] = v; found += 1; } }
            let (x, y) = (pair[0], pair[1]);
            let local = make_rake(&mut nodes, &mut used, vertex_leaf[x], &branches[x], branch_count[x], &values, &edge_map);
            if local < 0 { return -1; }
            let branch = append(&mut nodes, &mut used, BRANCH, edge_cluster[x][y], local, x as i16, &values, &edge_map);
            if branch < 0 || branch_count[y] >= N { return -1; }
            branches[y][branch_count[y]] = branch; branch_count[y] += 1;
            adj[x][y] = false; adj[y][x] = false; edge_cluster[x][y] = -1; edge_cluster[y][x] = -1;
            active[x] = false; active_count -= 1; break;
        }
        let mut leaves = [0usize; N]; let mut leaf_neighbor = [0usize; N]; let mut leaf_count = 0;
        for v in 0..n { if active[v] { let mut near = [0usize; 2]; if neighbor_count(&adj, &active, n, v, &mut near) == 1 { leaves[leaf_count] = v; leaf_neighbor[leaf_count] = near[0]; leaf_count += 1; } } }
        for i in 0..leaf_count {
            let (x, y) = (leaves[i], leaf_neighbor[i]);
            let local = make_rake(&mut nodes, &mut used, vertex_leaf[x], &branches[x], branch_count[x], &values, &edge_map);
            if local < 0 { return -1; }
            let branch = append(&mut nodes, &mut used, BRANCH, edge_cluster[x][y], local, x as i16, &values, &edge_map);
            if branch < 0 || branch_count[y] >= N { return -1; }
            branches[y][branch_count[y]] = branch; branch_count[y] += 1;
        }
        for i in 0..leaf_count { let (x,y)=(leaves[i],leaf_neighbor[i]); adj[x][y]=false; adj[y][x]=false; edge_cluster[x][y]=-1; edge_cluster[y][x]=-1; active[x]=false; active_count-=1; }
        if active_count <= 1 { break; }
        let mut chosen = [false; N]; let mut compress = [0usize; N]; let mut compress_count = 0;
        for x in 0..n { if active[x] { let mut near=[0usize;2]; if neighbor_count(&adj,&active,n,x,&mut near)!=2 { continue; } if !chosen[near[0]] && !chosen[near[1]] { chosen[x]=true; compress[compress_count]=x; compress_count+=1; } } }
        let mut px=[0usize;N];let mut py=[0usize;N];let mut pz=[0usize;N];let mut pc=[-1i16;N];
        for i in 0..compress_count {
            let x=compress[i];let mut near=[0usize;2];let _=neighbor_count(&adj,&active,n,x,&mut near);let (y,z)=(near[0],near[1]);
            let local=make_rake(&mut nodes,&mut used,vertex_leaf[x],&branches[x],branch_count[x],&values,&edge_map);if local<0{return -1;}
            let attached=append(&mut nodes,&mut used,ATTACH,edge_cluster[y][x],local,x as i16,&values,&edge_map);if attached<0{return -1;}
            let combined=append(&mut nodes,&mut used,COMPRESS,attached,edge_cluster[x][z],x as i16,&values,&edge_map);if combined<0{return -1;}
            px[i]=x;py[i]=y;pz[i]=z;pc[i]=combined;
        }
        for i in 0..compress_count { let (x,y,z)=(px[i],py[i],pz[i]);adj[y][x]=false;adj[x][y]=false;adj[x][z]=false;adj[z][x]=false;edge_cluster[y][x]=-1;edge_cluster[x][y]=-1;edge_cluster[x][z]=-1;edge_cluster[z][x]=-1;active[x]=false;active_count-=1; }
        for i in 0..compress_count { let (y,z)=(py[i],pz[i]);adj[y][z]=true;adj[z][y]=true;edge_cluster[y][z]=pc[i];edge_cluster[z][y]=pc[i]; }
    }
    let mut root_vertex=0;while !active[root_vertex]{root_vertex+=1;}
    let root=make_rake(&mut nodes,&mut used,vertex_leaf[root_vertex],&branches[root_vertex],branch_count[root_vertex],&values,&edge_map);if root<0{return -1;}
    let mut answers=[0i64;Q];
    for i in 0..q {
        let item=op_item[i];let node_id;
        if op_code[i]==0 { values[item]=op_first[i];node_id=vertex_leaf[item] as usize;recalc(&mut nodes,node_id,&values,&edge_map); }
        else { edge_map[item]=Affine{mul:op_first[i],add:op_second[i]};node_id=edge_leaf[item] as usize;recalc(&mut nodes,node_id,&values,&edge_map); }
        let mut ancestor=nodes[node_id].parent;while ancestor>=0 { let a=ancestor as usize;recalc(&mut nodes,a,&values,&edge_map);ancestor=nodes[a].parent; }
        answers[i]=query(&nodes,root as usize,&vertex_leaf,op_root[i],&values);if answers[i]<0{return -1;}
    }
    for i in 0..q { store(output,8*i,answers[i]); }
    required as i64
}
