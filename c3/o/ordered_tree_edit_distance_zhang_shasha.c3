module ordered_tree_edit_distance_zhang_shasha;

const long MAX_N = 8;
const usz MAX_LEN = 35;
const long INF = 1000000;

struct Tree { long n; long labels[8]; long children[8][8]; long child_count[8]; }
struct Post { long n; long labels[9]; long leftmost[9]; }

fn long post_visit(Tree* tree, long vertex, Post* post) {
    long left = 0;
    for (long k = 0; k < tree.child_count[vertex]; k++) {
        long child_left = post_visit(tree, tree.children[vertex][k], post);
        if (k == 0) left = child_left;
    }
    post.n += 1;
    long id = post.n;
    post.labels[id] = tree.labels[vertex];
    post.leftmost[id] = left == 0 ? id : left;
    return post.leftmost[id];
}

fn bool read_tree(long* input, usz* position, long n, Tree* tree) {
    tree.n = n;
    for (long v = 0; v < n; v++) {
        long label = input[*position]; *position += 1;
        if (label < 0 || label > 3) return false;
        tree.labels[v] = label;
    }
    long stack[8]; long top = 0; stack[0] = 0;
    for (long v = 0; v < n; v++) {
        long parent = input[*position]; *position += 1;
        if (v == 0) { if (parent != -1) return false; continue; }
        if (parent < 0 || parent >= v) return false;
        while (top >= 0 && stack[top] != parent) top -= 1;
        if (top < 0) return false;
        tree.children[parent][tree.child_count[parent]] = v;
        tree.child_count[parent] += 1;
        top += 1; stack[top] = v;
    }
    return true;
}

fn long distance(Tree* a, Tree* b) {
    Post pa = {}; Post pb = {};
    post_visit(a, 0, &pa); post_visit(b, 0, &pb);
    long key_a[9] = {}; long key_b[9] = {};
    for (long i = 1; i <= pa.n; i++) key_a[pa.leftmost[i]] = i;
    for (long j = 1; j <= pb.n; j++) key_b[pb.leftmost[j]] = j;
    long td[9][9] = {};
    for (long ra = 1; ra <= pa.n; ra++) {
        if (key_a[pa.leftmost[ra]] != ra) continue;
        for (long rb = 1; rb <= pb.n; rb++) {
            if (key_b[pb.leftmost[rb]] != rb) continue;
            long sa = pa.leftmost[ra]; long sb = pb.leftmost[rb];
            long fd[9][9];
            for (long x = 0; x <= 8; x++) for (long y = 0; y <= 8; y++) fd[x][y] = INF;
            fd[sa - 1][sb - 1] = 0;
            for (long x = sa; x <= ra; x++) fd[x][sb - 1] = fd[x - 1][sb - 1] + 1;
            for (long y = sb; y <= rb; y++) fd[sa - 1][y] = fd[sa - 1][y - 1] + 1;
            for (long x = sa; x <= ra; x++) for (long y = sb; y <= rb; y++) {
                long del = fd[x - 1][y] + 1; long ins = fd[x][y - 1] + 1;
                if (pa.leftmost[x] == sa && pb.leftmost[y] == sb) {
                    long rename = fd[x - 1][y - 1] + (pa.labels[x] != pb.labels[y] ? 1 : 0);
                    long best = del < ins ? del : ins; if (rename < best) best = rename;
                    fd[x][y] = best; td[x][y] = best;
                } else {
                    long join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y];
                    long best = del < ins ? del : ins; if (join < best) best = join;
                    fd[x][y] = best;
                }
            }
        }
    }
    return td[pa.n][pb.n];
}

fn long ordered_tree_edit_distance_zhang_shasha(long* input, usz length)
    @export("ordered_tree_edit_distance_zhang_shasha") {
    if (input == null || length < 6 || length > MAX_LEN) return -1;
    long n1 = input[0]; long n2 = input[1];
    if (n1 < 1 || n1 > MAX_N || n2 < 1 || n2 > MAX_N) return -1;
    if (length != (usz)(2 + 2 * n1 + 2 * n2)) return -1;
    usz position = 2; Tree a = {}; Tree b = {};
    if (!read_tree(input, &position, n1, &a) || !read_tree(input, &position, n2, &b)) return -1;
    return distance(&a, &b);
}
