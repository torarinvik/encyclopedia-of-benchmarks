from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_POINTS = MAX_N + MAX_Q
comptime MAX_TREE = 4 * MAX_POINTS + 8
comptime MAX_INPUT = 2 + 3 * MAX_N + 7 * MAX_Q + 1
comptime MOD = 998244353
comptime MAX_COORD = 1_000_000_000

struct Op(Copyable):
    var kind: Int64
    var a: Int64
    var b: Int64
    var c: Int64
    var d: Int64
    var e: Int64
    var f: Int64

struct Node(Copyable):
    var min_x: Int64
    var max_x: Int64
    var min_y: Int64
    var max_y: Int64
    var sum: Int64
    var lazy_a: Int64
    var lazy_b: Int64
    var active: Int

fn dpas_less(a: Int, b: Int, axis: Int, xs: InlineArray[Int64, MAX_POINTS], ys: InlineArray[Int64, MAX_POINTS]) -> Bool:
    var av = xs[a]; var bv = xs[b]
    if axis != 0: av = ys[a]; bv = ys[b]
    if av != bv: return av < bv
    var ao = ys[a]; var bo = ys[b]
    if axis != 0: ao = xs[a]; bo = xs[b]
    if ao != bo: return ao < bo
    return a < b

fn dpas_sort(mut order: InlineArray[Int, MAX_POINTS], low: Int, high: Int, axis: Int,
             xs: InlineArray[Int64, MAX_POINTS], ys: InlineArray[Int64, MAX_POINTS]):
    for i in range(low + 1, high):
        let point = order[i]
        var j = i
        while j > low and dpas_less(point, order[j - 1], axis, xs, ys):
            order[j] = order[j - 1]
            j -= 1
        order[j] = point

fn dpas_build(mut tree: InlineArray[Node, MAX_TREE], mut order: InlineArray[Int, MAX_POINTS],
              xs: InlineArray[Int64, MAX_POINTS], ys: InlineArray[Int64, MAX_POINTS],
              weights: InlineArray[Int64, MAX_POINTS], mut rank: InlineArray[Int, MAX_POINTS],
              low: Int, high: Int, index: Int, depth: Int, initial_n: Int):
    tree[index].lazy_a = 1
    if high - low == 1:
        let p = order[low]
        tree[index].min_x = xs[p]; tree[index].max_x = xs[p]
        tree[index].min_y = ys[p]; tree[index].max_y = ys[p]
        tree[index].active = 1 if p < initial_n else 0
        tree[index].sum = weights[p] if p < initial_n else 0
        rank[p] = low
        return
    dpas_sort(mut order, low, high, depth & 1, xs, ys)
    let mid = low + (high - low) // 2
    dpas_build(mut tree, mut order, xs, ys, weights, mut rank, low, mid, index * 2, depth + 1, initial_n)
    dpas_build(mut tree, mut order, xs, ys, weights, mut rank, mid, high, index * 2 + 1, depth + 1, initial_n)
    let l = tree[index * 2]; let r = tree[index * 2 + 1]
    tree[index].min_x = min(l.min_x, r.min_x); tree[index].max_x = max(l.max_x, r.max_x)
    tree[index].min_y = min(l.min_y, r.min_y); tree[index].max_y = max(l.max_y, r.max_y)
    tree[index].active = l.active + r.active
    tree[index].sum = (l.sum + r.sum) % MOD

fn dpas_apply(mut tree: InlineArray[Node, MAX_TREE], i: Int, a: Int64, b: Int64):
    if tree[i].active == 0: return
    tree[i].sum = (a * tree[i].sum + b * Int64(tree[i].active)) % MOD
    tree[i].lazy_a = a * tree[i].lazy_a % MOD
    tree[i].lazy_b = (a * tree[i].lazy_b + b) % MOD

fn dpas_push(mut tree: InlineArray[Node, MAX_TREE], i: Int, low: Int, high: Int):
    if high - low == 1 or (tree[i].lazy_a == 1 and tree[i].lazy_b == 0): return
    let a = tree[i].lazy_a; let b = tree[i].lazy_b
    dpas_apply(mut tree, i * 2, a, b); dpas_apply(mut tree, i * 2 + 1, a, b)
    tree[i].lazy_a = 1; tree[i].lazy_b = 0

fn dpas_disjoint(n: Node, l: Int64, d: Int64, r: Int64, u: Int64) -> Bool:
    return n.max_x < l or n.min_x >= r or n.max_y < d or n.min_y >= u
fn dpas_covered(n: Node, l: Int64, d: Int64, r: Int64, u: Int64) -> Bool:
    return l <= n.min_x and n.max_x < r and d <= n.min_y and n.max_y < u
fn dpas_pull(mut tree: InlineArray[Node, MAX_TREE], i: Int):
    tree[i].sum = (tree[i * 2].sum + tree[i * 2 + 1].sum) % MOD
    tree[i].active = tree[i * 2].active + tree[i * 2 + 1].active

fn dpas_rect_sum(mut tree: InlineArray[Node, MAX_TREE], i: Int, low: Int, high: Int,
                 l: Int64, d: Int64, r: Int64, u: Int64) -> Int64:
    let node = tree[i]
    if node.active == 0 or dpas_disjoint(node, l, d, r, u): return 0
    if dpas_covered(node, l, d, r, u): return node.sum
    dpas_push(mut tree, i, low, high)
    let mid = low + (high - low) // 2
    return (dpas_rect_sum(mut tree, i * 2, low, mid, l, d, r, u) + dpas_rect_sum(mut tree, i * 2 + 1, mid, high, l, d, r, u)) % MOD

fn dpas_rect_affine(mut tree: InlineArray[Node, MAX_TREE], i: Int, low: Int, high: Int,
                    l: Int64, d: Int64, r: Int64, u: Int64, a: Int64, b: Int64):
    let node = tree[i]
    if node.active == 0 or dpas_disjoint(node, l, d, r, u): return
    if dpas_covered(node, l, d, r, u): dpas_apply(mut tree, i, a, b); return
    dpas_push(mut tree, i, low, high)
    let mid = low + (high - low) // 2
    dpas_rect_affine(mut tree, i * 2, low, mid, l, d, r, u, a, b)
    dpas_rect_affine(mut tree, i * 2 + 1, mid, high, l, d, r, u, a, b)
    dpas_pull(mut tree, i)

fn dpas_set(mut tree: InlineArray[Node, MAX_TREE], i: Int, low: Int, high: Int, target: Int, weight: Int64):
    if high - low == 1:
        tree[i].sum = weight; tree[i].active = 1; tree[i].lazy_a = 1; tree[i].lazy_b = 0
        return
    dpas_push(mut tree, i, low, high)
    let mid = low + (high - low) // 2
    if target < mid: dpas_set(mut tree, i * 2, low, mid, target, weight)
    else: dpas_set(mut tree, i * 2 + 1, mid, high, target, weight)
    dpas_pull(mut tree, i)

fn dpas_write(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for b in range(8): output[offset + b] = ((bits >> (8 * b)) & 255).cast[UInt8]()

@export("dynamic_point_set_rectangle_affine_rectangle_sum")
fn dynamic_point_set_rectangle_affine_rectangle_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let nv = input[0]; let qv = input[1]
    if nv < 1 or nv > MAX_N or qv < 1 or qv > MAX_Q: return -1
    let n = nv.cast[Int](); let q = qv.cast[Int]()
    if 2 + 3 * n > length: return -1
    var xs = InlineArray[Int64, MAX_POINTS](fill=0); var ys = InlineArray[Int64, MAX_POINTS](fill=0)
    var weights = InlineArray[Int64, MAX_POINTS](fill=0); var ops = InlineArray[Op, MAX_Q](fill=Op(kind=0,a=0,b=0,c=0,d=0,e=0,f=0))
    var points = n; var active = n; var query_count = 0; var cursor = 2 + 3 * n
    for i in range(n):
        xs[i] = input[2 + 3 * i]; ys[i] = input[3 + 3 * i]; weights[i] = input[4 + 3 * i]
        if xs[i] < 0 or xs[i] > MAX_COORD or ys[i] < 0 or ys[i] > MAX_COORD or weights[i] < 0 or weights[i] >= MOD: return -1
    for oi in range(q):
        if cursor >= length: return -1
        let kind = input[cursor]; cursor += 1
        if kind == 0:
            if cursor + 3 > length or points >= MAX_POINTS: return -1
            let x=input[cursor]; let y=input[cursor+1]; let w=input[cursor+2]; cursor += 3
            if x < 0 or x > MAX_COORD or y < 0 or y > MAX_COORD or w < 0 or w >= MOD: return -1
            xs[points]=x; ys[points]=y; ops[oi]=Op(kind=kind,a=points.cast[Int64](),b=w,c=0,d=0,e=0,f=0); points += 1; active += 1
        elif kind == 1:
            if cursor + 2 > length: return -1
            let id=input[cursor]; let w=input[cursor+1]; cursor += 2
            if id < 0 or id >= active.cast[Int64]() or w < 0 or w >= MOD: return -1
            ops[oi]=Op(kind=kind,a=id,b=w,c=0,d=0,e=0,f=0)
        elif kind == 2 or kind == 3:
            let fields = 4 if kind == 2 else 6
            if cursor + fields > length: return -1
            let l=input[cursor]; let d=input[cursor+1]; let r=input[cursor+2]; let u=input[cursor+3]
            if l < 0 or l >= r or r > MAX_COORD or d < 0 or d >= u or u > MAX_COORD: return -1
            if kind == 2:
                cursor += 4; ops[oi]=Op(kind=kind,a=l,b=d,c=r,d=u,e=0,f=0); query_count += 1
            else:
                let a=input[cursor+4]; let b=input[cursor+5]; cursor += 6
                if a < 0 or a >= MOD or b < 0 or b >= MOD: return -1
                ops[oi]=Op(kind=kind,a=l,b=d,c=r,d=u,e=a,f=b)
        else: return -1
    if cursor != length: return -1
    let output_bytes = 8 * query_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)): return -2
    var tree = InlineArray[Node, MAX_TREE](fill=Node(min_x=0,max_x=0,min_y=0,max_y=0,sum=0,lazy_a=1,lazy_b=0,active=0))
    var order = InlineArray[Int, MAX_POINTS](fill=0); var rank = InlineArray[Int, MAX_POINTS](fill=0)
    for i in range(points): order[i]=i
    dpas_build(mut tree, mut order, xs, ys, weights, mut rank, 0, points, 1, 0, n)
    var answers = InlineArray[Int64, MAX_Q](fill=0); var answer_count = 0
    for oi in range(q):
        let op=ops[oi]
        if op.kind == 0 or op.kind == 1: dpas_set(mut tree,1,0,points,rank[op.a.cast[Int]()],op.b)
        elif op.kind == 2:
            answers[answer_count]=dpas_rect_sum(mut tree,1,0,points,op.a,op.b,op.c,op.d); answer_count += 1
        else: dpas_rect_affine(mut tree,1,0,points,op.a,op.b,op.c,op.d,op.e,op.f)
    for i in range(answer_count): dpas_write(output, i*8, answers[i])
    return output_bytes.cast[Int64]()
