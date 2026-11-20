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

#[derive(Clone, Copy)]
struct Node { kind: u8, count: usize, arg: u8, child: [u8; MAX_N] }
impl Node { const EMPTY: Self = Self { kind: LEAF, count: 0, arg: 0, child: [0; MAX_N] }; }
struct PqTree {
    nodes: [Node; MAX_NODES], color: [u8; MAX_NODES], free_id: [u8; MAX_NODES],
    next_id: usize, free_count: usize, root: usize,
}
impl PqTree { fn new() -> Self { Self { nodes: [Node::EMPTY; MAX_NODES], color: [0; MAX_NODES], free_id: [0; MAX_NODES], next_id: 0, free_count: 0, root: 0 } } }

fn new_node(t: &mut PqTree, kind: u8) -> Option<usize> {
    let id = if t.free_count != 0 { t.free_count -= 1; t.free_id[t.free_count] as usize }
    else { if t.next_id >= MAX_NODES { return None; } let id = t.next_id; t.next_id += 1; id };
    t.nodes[id] = Node::EMPTY; t.nodes[id].kind = kind; Some(id)
}
fn delete_node(t: &mut PqTree, id: usize) { t.nodes[id].count = 0; t.free_id[t.free_count] = id as u8; t.free_count += 1; }
fn push(t: &mut PqTree, id: usize, child: usize) { let at = t.nodes[id].count; t.nodes[id].child[at] = child as u8; t.nodes[id].count += 1; }

fn paint(t: &mut PqTree, id: usize, mask: u64) -> u8 {
    let node = t.nodes[id];
    if node.kind == LEAF { t.color[id] = if mask >> node.arg & 1 != 0 { BLACK } else { WHITE }; return t.color[id]; }
    let mut saw_white = false; let mut saw_black = false;
    for i in 0..node.count { let shade = paint(t, node.child[i] as usize, mask); saw_white |= shade != BLACK; saw_black |= shade != WHITE; }
    t.color[id] = if saw_white && saw_black { MIXED } else if saw_black { BLACK } else { WHITE }; t.color[id]
}
fn q_pattern(t: &PqTree, children: &[u8; MAX_N], count: usize) -> bool {
    let mut pivot: isize = -1; let mut mixed = 0;
    for i in 0..count { if t.color[children[i] as usize] == MIXED { pivot = i as isize; mixed += 1; if mixed > 1 { return false; } } }
    if mixed == 0 { for i in 0..count { if t.color[children[i] as usize] == BLACK { pivot = i as isize; break; } } }
    if pivot < 0 { return false; }
    for i in 0..pivot as usize { if t.color[children[i] as usize] != WHITE { return false; } }
    for i in pivot as usize + 1..count { if t.color[children[i] as usize] != BLACK { return false; } }
    true
}

fn split(t: &mut PqTree, id: usize, out: &mut [u8; MAX_N]) -> Option<usize> {
    let node = t.nodes[id];
    if t.color[id] != MIXED { out[0] = id as u8; return Some(1); }
    let old = node.child;
    let mut white = [0u8; MAX_N]; let mut black = [0u8; MAX_N]; let mut mixed = [0u8; MAX_N];
    let (mut nw, mut nb, mut nm, mut used) = (0usize, 0usize, 0usize, 0usize);
    for i in 0..node.count { let child = old[i]; match t.color[child as usize] { WHITE => { white[nw] = child; nw += 1; }, BLACK => { black[nb] = child; nb += 1; }, _ => { mixed[nm] = child; nm += 1; } } }
    if node.kind == Q_NODE {
        let mut order = old;
        if !q_pattern(t, &order, node.count) { order[..node.count].reverse(); if !q_pattern(t, &order, node.count) { return None; } }
        for i in 0..node.count {
            let child = order[i] as usize;
            if t.color[child] == MIXED { let mut part = [0u8; MAX_N]; let count = split(t, child, &mut part)?; for j in 0..count { out[used] = part[j]; used += 1; } }
            else { out[used] = child as u8; used += 1; }
        }
    } else {
        if nm > 1 { return None; }
        if nw > 0 { let group = new_node(t, P_NODE)?; for i in 0..nw { push(t, group, white[i] as usize); } out[used] = group as u8; used += 1; }
        if nm > 0 { let mut part = [0u8; MAX_N]; let count = split(t, mixed[0] as usize, &mut part)?; for i in 0..count { out[used] = part[i]; used += 1; } }
        if nb > 0 { let group = new_node(t, P_NODE)?; for i in 0..nb { push(t, group, black[i] as usize); } out[used] = group as u8; used += 1; }
    }
    delete_node(t, id); Some(used)
}

fn work(t: &mut PqTree, id: usize) -> bool {
    let node = t.nodes[id]; if t.color[id] != MIXED { return true; }
    let mut old = [0u8; MAX_N]; let mut white = [0u8; MAX_N]; let mut black = [0u8; MAX_N]; let mut mixed = [0u8; MAX_N];
    let (mut nw, mut nb, mut nm) = (0usize, 0usize, 0usize);
    for i in 0..node.count { old[i] = node.child[i]; match t.color[old[i] as usize] { WHITE => { white[nw] = old[i]; nw += 1; }, BLACK => { black[nb] = old[i]; nb += 1; }, _ => { mixed[nm] = old[i]; nm += 1; } } }
    if node.kind == P_NODE {
        if nb == 0 && nm == 1 { return work(t, mixed[0] as usize); }
        if nm > 2 { return false; }
        let Some(q) = new_node(t, Q_NODE) else { return false; };
        for i in 0..nw { t.nodes[id].child[i] = white[i]; }
        t.nodes[id].child[nw] = q as u8; t.nodes[id].count = nw + 1;
        if nm > 0 { let mut part = [0u8; MAX_N]; let Some(count) = split(t, mixed[0] as usize, &mut part) else { return false; }; for i in 0..count { push(t, q, part[i] as usize); } }
        if nb > 0 { let Some(group) = new_node(t, P_NODE) else { return false; }; for i in 0..nb { push(t, group, black[i] as usize); } push(t, q, group); }
        if nm == 2 { let mut part = [0u8; MAX_N]; let Some(count) = split(t, mixed[1] as usize, &mut part) else { return false; }; for i in (0..count).rev() { push(t, q, part[i] as usize); } }
        return true;
    }
    let (mut left, mut right) = (None, None);
    for i in 0..node.count { if t.color[old[i] as usize] != WHITE { if left.is_none() { left = Some(i); } right = Some(i); } }
    let (Some(left), Some(right)) = (left, right) else { return false; };
    for i in left + 1..right { if t.color[old[i] as usize] != BLACK { return false; } }
    if left == right && t.color[old[left] as usize] == MIXED { return work(t, old[left] as usize); }
    let mut result = [0u8; MAX_N]; let mut used = 0;
    for i in 0..left { result[used] = old[i]; used += 1; }
    let mut part = [0u8; MAX_N]; let Some(count) = split(t, old[left] as usize, &mut part) else { return false; };
    for i in 0..count { result[used] = part[i]; used += 1; }
    for i in left + 1..right { result[used] = old[i]; used += 1; }
    if right != left { let Some(count) = split(t, old[right] as usize, &mut part) else { return false; }; for i in (0..count).rev() { result[used] = part[i]; used += 1; } }
    for i in right + 1..node.count { result[used] = old[i]; used += 1; }
    t.nodes[id].count = used; t.nodes[id].child[..used].copy_from_slice(&result[..used]); true
}

fn normalize(t: &mut PqTree, id: usize) -> usize {
    let node = t.nodes[id]; if node.kind == LEAF { return id; }
    for i in 0..node.count { t.nodes[id].child[i] = normalize(t, node.child[i] as usize) as u8; }
    if t.nodes[id].count == 1 { let child = t.nodes[id].child[0] as usize; delete_node(t, id); return child; }
    if t.nodes[id].kind == Q_NODE && t.nodes[id].count == 2 { t.nodes[id].kind = P_NODE; }
    id
}
fn compare(t: &PqTree, a: usize, b: usize) -> i32 {
    let x = t.nodes[a]; let y = t.nodes[b];
    let xa = if x.kind == LEAF { x.arg } else { x.count as u8 }; let ya = if y.kind == LEAF { y.arg } else { y.count as u8 };
    if x.kind != y.kind { return if x.kind < y.kind { -1 } else { 1 }; }
    if xa != ya { return if xa < ya { -1 } else { 1 }; }
    if x.kind != LEAF { for i in 0..x.count { let c = compare(t, x.child[i] as usize, y.child[i] as usize); if c != 0 { return c; } } }
    0
}
fn canonicalize(t: &mut PqTree, id: usize) {
    let node = t.nodes[id]; if node.kind == LEAF { return; }
    for i in 0..node.count { canonicalize(t, node.child[i] as usize); }
    if node.kind == P_NODE {
        for i in 1..node.count { let item = t.nodes[id].child[i]; let mut j = i; while j > 0 && compare(t, item as usize, t.nodes[id].child[j - 1] as usize) < 0 { t.nodes[id].child[j] = t.nodes[id].child[j - 1]; j -= 1; } t.nodes[id].child[j] = item; }
    } else {
        let mut order = 0; for i in 0..node.count { order = compare(t, node.child[i] as usize, node.child[node.count - 1 - i] as usize); if order != 0 { break; } }
        if order > 0 { t.nodes[id].child[..node.count].reverse(); }
    }
}
fn frontier_count(t: &PqTree, id: usize) -> i64 {
    let node = t.nodes[id]; if node.kind == LEAF { return 1; }
    let mut result = 1i64; for i in 0..node.count { result *= frontier_count(t, node.child[i] as usize); }
    if node.kind == P_NODE { for factor in 2..=node.count { result *= factor as i64; } } else { result *= 2; } result
}
fn node_count(t: &PqTree, id: usize) -> usize { let node=t.nodes[id]; let mut result=1; if node.kind!=LEAF { for i in 0..node.count { result+=node_count(t,node.child[i] as usize); } } result }
fn serialize(t: &PqTree, id: usize, words: &mut [i64; 81], used: &mut usize) {
    let node=t.nodes[id]; words[*used]=node.kind as i64; *used+=1; words[*used]=if node.kind==LEAF {node.arg as i64} else {node.count as i64}; *used+=1;
    if node.kind!=LEAF { for i in 0..node.count { serialize(t,node.child[i] as usize,words,used); } }
}
fn store_i64(output: &mut [u8; MAX_OUTPUT], offset: usize, value: i64) { let bits=value as u64; for i in 0..8 { output[offset+i]=(bits>>(8*i)) as u8; } }

#[no_mangle]
pub unsafe extern "C" fn pq_tree_consecutive_ones(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n_raw = *input; let m_raw = *input.add(1);
    if n_raw < 2 || n_raw > MAX_N as i64 || m_raw < 0 || m_raw > MAX_M as i64 || length != 2 + m_raw as usize { return -1; }
    let n=n_raw as usize; let m=m_raw as usize; let valid=(1u64<<n)-1;
    for row in 0..m { let mask=*input.add(2+row); if mask<0 || (mask as u64 & !valid)!=0 { return -1; } }
    let mut t=PqTree::new(); t.next_id=n+1; t.root=n;
    for i in 0..n { t.nodes[i].kind=LEAF; t.nodes[i].arg=i as u8; }
    t.nodes[n].kind=P_NODE; t.nodes[n].count=n; for i in 0..n { t.nodes[n].child[i]=i as u8; }
    for row in 0..m { paint(&mut t,t.root,*input.add(2+row) as u64); if !work(&mut t,t.root) { let mut staged=[0u8;MAX_OUTPUT]; for i in 0..3 { store_i64(&mut staged,i*8,0); } if output.is_null() || capacity<24 { return -2; } for i in 0..24 { *output.add(i)=staged[i]; } return 24; } t.root=normalize(&mut t,t.root); }
    canonicalize(&mut t,t.root); let mut words=[0i64;81]; let mut used=0; words[used]=1;used+=1;words[used]=frontier_count(&t,t.root);used+=1;words[used]=node_count(&t,t.root) as i64;used+=1;serialize(&t,t.root,&mut words,&mut used);
    let mut staged=[0u8;MAX_OUTPUT];for i in 0..used {store_i64(&mut staged,i*8,words[i]);}let bytes=used*8;
    if output.is_null()||capacity<bytes{return -2;}for i in 0..bytes{*output.add(i)=staged[i];}bytes as i64
}
