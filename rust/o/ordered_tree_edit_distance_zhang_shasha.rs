const MAX_N: usize = 8;
const MAX_LEN: usize = 35;
const INF: i64 = 1_000_000;

#[derive(Clone, Copy)]
struct Tree {
    n: usize,
    labels: [i64; MAX_N],
    children: [[usize; MAX_N]; MAX_N],
    child_count: [usize; MAX_N],
}

impl Default for Tree {
    fn default() -> Self {
        Self { n: 0, labels: [0; MAX_N], children: [[0; MAX_N]; MAX_N], child_count: [0; MAX_N] }
    }
}

struct Post { n: usize, labels: [i64; MAX_N + 1], leftmost: [usize; MAX_N + 1] }
impl Default for Post {
    fn default() -> Self { Self { n: 0, labels: [0; MAX_N + 1], leftmost: [0; MAX_N + 1] } }
}

fn post_visit(tree: &Tree, vertex: usize, post: &mut Post) -> usize {
    let mut left = 0;
    for k in 0..tree.child_count[vertex] {
        let child_left = post_visit(tree, tree.children[vertex][k], post);
        if k == 0 { left = child_left; }
    }
    post.n += 1;
    let id = post.n;
    post.labels[id] = tree.labels[vertex];
    post.leftmost[id] = if left == 0 { id } else { left };
    post.leftmost[id]
}

fn read_tree(input: &[i64], position: &mut usize, n: usize) -> Option<Tree> {
    let mut tree = Tree::default();
    tree.n = n;
    for v in 0..n {
        let label = input[*position]; *position += 1;
        if !(0..=3).contains(&label) { return None; }
        tree.labels[v] = label;
    }
    let mut stack = [0usize; MAX_N];
    let mut top: isize = 0;
    for v in 0..n {
        let parent = input[*position]; *position += 1;
        if v == 0 {
            if parent != -1 { return None; }
            stack[0] = 0;
            continue;
        }
        if parent < 0 || parent >= v as i64 { return None; }
        while top >= 0 && stack[top as usize] != parent as usize { top -= 1; }
        if top < 0 { return None; }
        let p = parent as usize;
        tree.children[p][tree.child_count[p]] = v;
        tree.child_count[p] += 1;
        top += 1; stack[top as usize] = v;
    }
    Some(tree)
}

fn distance(a: &Tree, b: &Tree) -> i64 {
    let mut pa = Post::default(); let mut pb = Post::default();
    post_visit(a, 0, &mut pa); post_visit(b, 0, &mut pb);
    let mut key_a = [0usize; MAX_N + 1]; let mut key_b = [0usize; MAX_N + 1];
    for i in 1..=pa.n { key_a[pa.leftmost[i]] = i; }
    for j in 1..=pb.n { key_b[pb.leftmost[j]] = j; }
    let mut td = [[0i64; MAX_N + 1]; MAX_N + 1];
    for ra in 1..=pa.n {
        if key_a[pa.leftmost[ra]] != ra { continue; }
        for rb in 1..=pb.n {
            if key_b[pb.leftmost[rb]] != rb { continue; }
            let sa = pa.leftmost[ra]; let sb = pb.leftmost[rb];
            let mut fd = [[INF; MAX_N + 1]; MAX_N + 1];
            fd[sa - 1][sb - 1] = 0;
            for x in sa..=ra { fd[x][sb - 1] = fd[x - 1][sb - 1] + 1; }
            for y in sb..=rb { fd[sa - 1][y] = fd[sa - 1][y - 1] + 1; }
            for x in sa..=ra {
                for y in sb..=rb {
                    let del = fd[x - 1][y] + 1;
                    let ins = fd[x][y - 1] + 1;
                    if pa.leftmost[x] == sa && pb.leftmost[y] == sb {
                        let rename_cost = if pa.labels[x] != pb.labels[y] { 1 } else { 0 };
                        let rename = fd[x - 1][y - 1] + rename_cost;
                        let best = del.min(ins).min(rename);
                        fd[x][y] = best; td[x][y] = best;
                    } else {
                        let join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y];
                        fd[x][y] = del.min(ins).min(join);
                    }
                }
            }
        }
    }
    td[pa.n][pb.n]
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 6 || values.len() > MAX_LEN { return -1; }
    let n1v = values[0]; let n2v = values[1];
    if !(1..=MAX_N as i64).contains(&n1v) || !(1..=MAX_N as i64).contains(&n2v) { return -1; }
    let n1 = n1v as usize; let n2 = n2v as usize;
    if values.len() != 2 + 2 * n1 + 2 * n2 { return -1; }
    let mut position = 2;
    let Some(a) = read_tree(values, &mut position, n1) else { return -1; };
    let Some(b) = read_tree(values, &mut position, n2) else { return -1; };
    distance(&a, &b)
}

#[no_mangle]
pub unsafe extern "C" fn ordered_tree_edit_distance_zhang_shasha(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_LEN { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
