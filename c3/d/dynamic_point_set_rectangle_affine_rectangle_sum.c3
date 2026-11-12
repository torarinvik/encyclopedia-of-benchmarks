module dynamic_point_set_rectangle_affine_rectangle_sum;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_POINTS = MAX_N + MAX_Q;
const usz MAX_TREE = 4 * MAX_POINTS + 8;
const usz MAX_INPUT = 2 + 3 * MAX_N + 7 * MAX_Q + 1;
const long MOD = 998244353L;
const long MAX_COORD = 1000000000L;

struct Op { long kind, a, b, c, d, e, f; }
struct Node { long min_x, max_x, min_y, max_y, sum, lazy_a, lazy_b; usz active; }

fn bool less_point(usz a, usz b, usz axis, long* xs, long* ys) {
    long av = axis == 0 ? xs[a] : ys[a]; long bv = axis == 0 ? xs[b] : ys[b];
    if (av != bv) return av < bv;
    long ao = axis == 0 ? ys[a] : xs[a]; long bo = axis == 0 ? ys[b] : xs[b];
    if (ao != bo) return ao < bo;
    return a < b;
}
fn void sort_points(usz* order, usz low, usz high, usz axis, long* xs, long* ys) {
    for (usz i = low + 1; i < high; i++) {
        usz point = order[i]; usz j = i;
        while (j > low && less_point(point, order[j - 1], axis, xs, ys)) { order[j] = order[j - 1]; j--; }
        order[j] = point;
    }
}
fn void build(Node* tree, usz* order, long* xs, long* ys, long* weights, usz* rank,
              usz low, usz high, usz index, usz depth, usz initial_n) {
    tree[index].lazy_a = 1;
    if (high - low == 1) {
        usz p = order[low]; tree[index].min_x = xs[p]; tree[index].max_x = xs[p];
        tree[index].min_y = ys[p]; tree[index].max_y = ys[p];
        tree[index].active = p < initial_n ? 1 : 0; tree[index].sum = p < initial_n ? weights[p] : 0;
        rank[p] = low; return;
    }
    sort_points(order, low, high, depth & 1, xs, ys); usz mid = low + (high - low) / 2;
    build(tree, order, xs, ys, weights, rank, low, mid, index * 2, depth + 1, initial_n);
    build(tree, order, xs, ys, weights, rank, mid, high, index * 2 + 1, depth + 1, initial_n);
    Node l = tree[index * 2]; Node r = tree[index * 2 + 1];
    tree[index].min_x = l.min_x < r.min_x ? l.min_x : r.min_x;
    tree[index].max_x = l.max_x > r.max_x ? l.max_x : r.max_x;
    tree[index].min_y = l.min_y < r.min_y ? l.min_y : r.min_y;
    tree[index].max_y = l.max_y > r.max_y ? l.max_y : r.max_y;
    tree[index].active = l.active + r.active; tree[index].sum = (l.sum + r.sum) % MOD;
}
fn void apply(Node* tree, usz i, long a, long b) {
    if (tree[i].active == 0) return;
    tree[i].sum = (a * tree[i].sum + b * (long)tree[i].active) % MOD;
    tree[i].lazy_a = a * tree[i].lazy_a % MOD; tree[i].lazy_b = (a * tree[i].lazy_b + b) % MOD;
}
fn void push(Node* tree, usz i, usz low, usz high) {
    if (high - low == 1 || (tree[i].lazy_a == 1 && tree[i].lazy_b == 0)) return;
    apply(tree, i * 2, tree[i].lazy_a, tree[i].lazy_b); apply(tree, i * 2 + 1, tree[i].lazy_a, tree[i].lazy_b);
    tree[i].lazy_a = 1; tree[i].lazy_b = 0;
}
fn bool disjoint(Node n, long l, long d, long r, long u) { return n.max_x < l || n.min_x >= r || n.max_y < d || n.min_y >= u; }
fn bool covered(Node n, long l, long d, long r, long u) { return l <= n.min_x && n.max_x < r && d <= n.min_y && n.max_y < u; }
fn void pull(Node* tree, usz i) { tree[i].sum = (tree[i * 2].sum + tree[i * 2 + 1].sum) % MOD; tree[i].active = tree[i * 2].active + tree[i * 2 + 1].active; }
fn long rect_sum(Node* tree, usz i, usz low, usz high, long l, long d, long r, long u) {
    Node n = tree[i]; if (n.active == 0 || disjoint(n, l, d, r, u)) return 0;
    if (covered(n, l, d, r, u)) return n.sum;
    push(tree, i, low, high); usz mid = low + (high - low) / 2;
    return (rect_sum(tree, i * 2, low, mid, l, d, r, u) + rect_sum(tree, i * 2 + 1, mid, high, l, d, r, u)) % MOD;
}
fn void rect_affine(Node* tree, usz i, usz low, usz high, long l, long d, long r, long u, long a, long b) {
    Node n = tree[i]; if (n.active == 0 || disjoint(n, l, d, r, u)) return;
    if (covered(n, l, d, r, u)) { apply(tree, i, a, b); return; }
    push(tree, i, low, high); usz mid = low + (high - low) / 2;
    rect_affine(tree, i * 2, low, mid, l, d, r, u, a, b);
    rect_affine(tree, i * 2 + 1, mid, high, l, d, r, u, a, b); pull(tree, i);
}
fn void set_point(Node* tree, usz i, usz low, usz high, usz target, long weight) {
    if (high - low == 1) { tree[i].sum = weight; tree[i].active = 1; tree[i].lazy_a = 1; tree[i].lazy_b = 0; return; }
    push(tree, i, low, high); usz mid = low + (high - low) / 2;
    if (target < mid) set_point(tree, i * 2, low, mid, target, weight); else set_point(tree, i * 2 + 1, mid, high, target, weight);
    pull(tree, i);
}
fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[offset + b] = (uint8)(bits >> (8 * b));
}

fn long dynamic_point_set_rectangle_affine_rectangle_sum(long* input, usz length, uint8* output, usz capacity)
    @export("dynamic_point_set_rectangle_affine_rectangle_sum") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_Q) return -1;
    usz n = (usz)input[0]; usz q = (usz)input[1]; if (2 + 3 * n > length) return -1;
    long[MAX_POINTS] xs = zeroed; long[MAX_POINTS] ys = zeroed; long[MAX_POINTS] weights = zeroed; Op[MAX_Q] ops = zeroed;
    usz points = n; usz active = n; usz query_count = 0;
    for (usz i = 0; i < n; i++) {
        xs[i] = input[2 + 3 * i]; ys[i] = input[3 + 3 * i]; weights[i] = input[4 + 3 * i];
        if (xs[i] < 0 || xs[i] > MAX_COORD || ys[i] < 0 || ys[i] > MAX_COORD || weights[i] < 0 || weights[i] >= MOD) return -1;
    }
    usz cursor = 2 + 3 * n;
    for (usz oi = 0; oi < q; oi++) {
        if (cursor >= length) return -1; long kind = input[cursor]; cursor++;
        if (kind == 0) {
            if (cursor + 3 > length || points >= MAX_POINTS) return -1;
            long x=input[cursor]; long y=input[cursor+1]; long w=input[cursor+2]; cursor+=3;
            if (x<0 || x>MAX_COORD || y<0 || y>MAX_COORD || w<0 || w>=MOD) return -1;
            xs[points]=x; ys[points]=y; ops[oi]={kind,(long)points,w,0,0,0,0}; points++; active++;
        } else if (kind == 1) {
            if (cursor+2>length) return -1; long id=input[cursor]; long w=input[cursor+1]; cursor+=2;
            if (id<0 || id>=(long)active || w<0 || w>=MOD) return -1; ops[oi]={kind,id,w,0,0,0,0};
        } else if (kind == 2 || kind == 3) {
            usz fields = kind == 2 ? 4 : 6; if (cursor+fields>length) return -1;
            long l=input[cursor]; long d=input[cursor+1]; long r=input[cursor+2]; long u=input[cursor+3];
            if (l<0 || l>=r || r>MAX_COORD || d<0 || d>=u || u>MAX_COORD) return -1;
            if (kind==2) { cursor+=4; ops[oi]={kind,l,d,r,u,0,0}; query_count++; }
            else { long a=input[cursor+4]; long b=input[cursor+5]; cursor+=6; if(a<0 || a>=MOD || b<0 || b>=MOD)return -1; ops[oi]={kind,l,d,r,u,a,b}; }
        } else return -1;
    }
    if (cursor != length) return -1; usz output_bytes=8*query_count;
    if (output_bytes>0 && (output==null || capacity<output_bytes)) return -2;
    Node[MAX_TREE] tree = zeroed; usz[MAX_POINTS] order = zeroed; usz[MAX_POINTS] rank = zeroed;
    for (usz i=0;i<points;i++) order[i]=i;
    build(&tree[0],&order[0],&xs[0],&ys[0],&weights[0],&rank[0],0,points,1,0,n);
    long[MAX_Q] answers = zeroed; usz answer_count=0;
    for (usz oi=0;oi<q;oi++) { Op op=ops[oi];
        if(op.kind==0 || op.kind==1) set_point(&tree[0],1,0,points,rank[(usz)op.a],op.b);
        else if(op.kind==2) { answers[answer_count]=rect_sum(&tree[0],1,0,points,op.a,op.b,op.c,op.d); answer_count++; }
        else rect_affine(&tree[0],1,0,points,op.a,op.b,op.c,op.d,op.e,op.f);
    }
    for (usz i=0;i<answer_count;i++) store_le(output,8*i,answers[i]);
    return (long)output_bytes;
}
