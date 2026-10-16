const MAX_OPS: usize = 128;
const NIL: usize = 0;
#[derive(Clone, Copy)]
struct Node { key: i64, left: usize, right: usize, parent: usize, red: bool }
impl Default for Node { fn default() -> Self { Self { key: 0, left: 0, right: 0, parent: 0, red: false } } }
fn left_rotate(t: &mut [Node; MAX_OPS + 1], root: &mut usize, x: usize) {
    let y = t[x].right; t[x].right = t[y].left;
    if t[y].left != NIL { let child = t[y].left; t[child].parent = x; }
    t[y].parent = t[x].parent;
    let parent = t[x].parent;
    if parent == NIL { *root = y; }
    else if x == t[parent].left { t[parent].left = y; } else { t[parent].right = y; }
    t[y].left = x; t[x].parent = y;
}
fn right_rotate(t: &mut [Node; MAX_OPS + 1], root: &mut usize, y: usize) {
    let x = t[y].left; t[y].left = t[x].right;
    if t[x].right != NIL { let child = t[x].right; t[child].parent = y; }
    t[x].parent = t[y].parent;
    let parent = t[y].parent;
    if parent == NIL { *root = x; }
    else if y == t[parent].right { t[parent].right = x; } else { t[parent].left = x; }
    t[x].right = y; t[y].parent = x;
}
fn find_node(t: &[Node; MAX_OPS + 1], mut root: usize, key: i64) -> usize {
    while root != NIL && t[root].key != key { root = if key < t[root].key { t[root].left } else { t[root].right }; }
    root
}
fn insert_node(t: &mut [Node; MAX_OPS + 1], root: &mut usize, mut z: usize) {
    let (mut y, mut x) = (NIL, *root);
    while x != NIL { y = x; x = if t[z].key < t[x].key { t[x].left } else { t[x].right }; }
    t[z].parent = y;
    if y == NIL { *root = z; } else if t[z].key < t[y].key { t[y].left = z; } else { t[y].right = z; }
    t[z].left = NIL; t[z].right = NIL; t[z].red = true;
    while t[t[z].parent].red {
        let p = t[z].parent; let g = t[p].parent;
        if p == t[g].left {
            y = t[g].right;
            if t[y].red { t[p].red = false; t[y].red = false; t[g].red = true; z = g; }
            else { if z == t[p].right { z = p; left_rotate(t, root, z); }
                let p = t[z].parent; let g = t[p].parent; t[p].red = false; t[g].red = true; right_rotate(t, root, g); }
        } else {
            y = t[g].left;
            if t[y].red { t[p].red = false; t[y].red = false; t[g].red = true; z = g; }
            else { if z == t[p].left { z = p; right_rotate(t, root, z); }
                let p = t[z].parent; let g = t[p].parent; t[p].red = false; t[g].red = true; left_rotate(t, root, g); }
        }
    }
    t[*root].red = false;
}
fn minimum(t: &[Node; MAX_OPS + 1], mut x: usize) -> usize { while t[x].left != NIL { x = t[x].left; } x }
fn transplant(t: &mut [Node; MAX_OPS + 1], root: &mut usize, u: usize, v: usize) {
    let parent = t[u].parent;
    if parent == NIL { *root = v; } else if u == t[parent].left { t[parent].left = v; } else { t[parent].right = v; }
    t[v].parent = parent;
}
fn delete_fix(t: &mut [Node; MAX_OPS + 1], root: &mut usize, mut x: usize) {
    while x != *root && !t[x].red {
        let p = t[x].parent;
        if x == t[p].left {
            let mut w = t[p].right;
            if t[w].red { t[w].red = false; t[p].red = true; left_rotate(t, root, p); w = t[t[x].parent].right; }
            if !t[t[w].left].red && !t[t[w].right].red { t[w].red = true; x = t[x].parent; }
            else { if !t[t[w].right].red { let wl = t[w].left; t[wl].red = false; t[w].red = true; right_rotate(t, root, w); w = t[t[x].parent].right; }
                let p = t[x].parent; let wr = t[w].right; t[w].red = t[p].red; t[p].red = false; t[wr].red = false; left_rotate(t, root, p); x = *root; }
        } else {
            let mut w = t[p].left;
            if t[w].red { t[w].red = false; t[p].red = true; right_rotate(t, root, p); w = t[t[x].parent].left; }
            if !t[t[w].right].red && !t[t[w].left].red { t[w].red = true; x = t[x].parent; }
            else { if !t[t[w].left].red { let wr = t[w].right; t[wr].red = false; t[w].red = true; left_rotate(t, root, w); w = t[t[x].parent].left; }
                let p = t[x].parent; let wl = t[w].left; t[w].red = t[p].red; t[p].red = false; t[wl].red = false; right_rotate(t, root, p); x = *root; }
        }
    }
    t[x].red = false;
}
fn delete_node(t: &mut [Node; MAX_OPS + 1], root: &mut usize, z: usize) {
    let (mut y, mut x) = (z, NIL); let mut was_red = t[y].red;
    if t[z].left == NIL { x = t[z].right; transplant(t, root, z, t[z].right); }
    else if t[z].right == NIL { x = t[z].left; transplant(t, root, z, t[z].left); }
    else { y = minimum(t, t[z].right); was_red = t[y].red; x = t[y].right;
        if t[y].parent == z { t[x].parent = y; }
        else { let yr = t[y].right; transplant(t, root, y, yr); let zr = t[z].right; t[y].right = zr; t[zr].parent = y; }
        let zl = t[z].left; let zred = t[z].red;
        transplant(t, root, z, y); t[y].left = zl; t[zl].parent = y; t[y].red = zred;
    }
    if !was_red { delete_fix(t, root, x); }
}
unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) { for (i, b) in value.to_le_bytes().iter().enumerate() { *output.add(offset+i) = *b; } }
#[no_mangle]
pub unsafe extern "C" fn red_black_tree_unique_key_ops(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    if !(0..=MAX_OPS as i64).contains(&n64) || length != 1 + 2 * n64 as usize { return -1; }
    let n = n64 as usize; let (mut active_count, mut search_count) = (0usize, 0usize); let mut active = [0i64; MAX_OPS];
    for i in 0..n { let (op, key) = (values[1+2*i], values[2+2*i]);
        if !(0..=2).contains(&op) || key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
        let found = active[..active_count].iter().position(|&v| v == key);
        if op == 0 { if found.is_some() || active_count >= MAX_OPS { return -1; } active[active_count] = key; active_count += 1; }
        else if op == 1 { search_count += 1; }
        else { let Some(pos) = found else { return -1; }; active.copy_within(pos+1..active_count, pos); active_count -= 1; }
    }
    let mut t = [Node::default(); MAX_OPS+1]; let mut root = NIL; let mut next = 1usize; let mut results = [0i64; MAX_OPS]; let mut result_count = 0;
    for i in 0..n { let (op, key) = (values[1+2*i], values[2+2*i]);
        if op == 0 { t[next].key = key; insert_node(&mut t, &mut root, next); next += 1; }
        else if op == 1 { results[result_count] = (find_node(&t, root, key) != NIL) as i64; result_count += 1; }
        else { let z = find_node(&t, root, key); delete_node(&mut t, &mut root, z); }
    }
    let bytes = (2 + active_count + search_count) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    unsafe { put_i64(output, 0, active_count as i64); }
    let mut stack = [0usize; MAX_OPS]; let (mut top, mut current) = (0usize, root); let mut out = 1usize;
    while current != NIL || top > 0 { while current != NIL { stack[top] = current; top += 1; current = t[current].left; }
        top -= 1; current = stack[top]; unsafe { put_i64(output, out*8, t[current].key); } out += 1; current = t[current].right; }
    unsafe { put_i64(output, out*8, search_count as i64); } out += 1;
    for value in results.iter().take(search_count) { unsafe { put_i64(output, out*8, *value); } out += 1; }
    bytes as i64
}
