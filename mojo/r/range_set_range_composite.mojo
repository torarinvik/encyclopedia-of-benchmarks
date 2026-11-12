from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)
comptime MAX_N = 64
comptime MAX_Q = 32
comptime MAX_INPUT = 291
comptime TREE_N = 4 * MAX_N + 5

struct Affine:
    var a: Int64
    var b: Int64

struct Node:
    var value: Affine
    var lazy_a: Int64
    var lazy_b: Int64
    var has_lazy: Bool

struct Operation:
    var kind: Int64
    var left: Int
    var right: Int
    var x: Int64
    var y: Int64

fn identity() -> Affine:
    var result: Affine
    result.a = 1
    result.b = 0
    return result

fn compose(after: Affine, before: Affine) -> Affine:
    var result: Affine
    result.a = (after.a * before.a) % MODULUS
    result.b = (after.a * before.b + after.b) % MODULUS
    return result

fn power_map(a: Int64, b: Int64, count: Int) -> Affine:
    var result = identity()
    var base: Affine
    base.a = a
    base.b = b
    var exponent = count
    while exponent > 0:
        if exponent % 2 == 1: result = compose(base, result)
        base = compose(base, base)
        exponent = exponent / 2
    return result

fn build(tree: UnsafePointer[Node, MutAnyOrigin], node: Int, left: Int, right: Int,
         initial_a: UnsafePointer[Int64, MutAnyOrigin], initial_b: UnsafePointer[Int64, MutAnyOrigin]):
    if right - left == 1:
        tree[node].value.a = initial_a[left]
        tree[node].value.b = initial_b[left]
        return
    let middle = left + (right - left) / 2
    build(tree, node * 2, left, middle, initial_a, initial_b)
    build(tree, node * 2 + 1, middle, right, initial_a, initial_b)
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)

fn apply(tree: UnsafePointer[Node, MutAnyOrigin], node: Int, left: Int, right: Int, a: Int64, b: Int64):
    tree[node].value = power_map(a, b, right - left)
    tree[node].lazy_a = a
    tree[node].lazy_b = b
    tree[node].has_lazy = True

fn push(tree: UnsafePointer[Node, MutAnyOrigin], node: Int, left: Int, right: Int):
    if not tree[node].has_lazy or right - left == 1: return
    let middle = left + (right - left) / 2
    let a = tree[node].lazy_a
    let b = tree[node].lazy_b
    apply(tree, node * 2, left, middle, a, b)
    apply(tree, node * 2 + 1, middle, right, a, b)
    tree[node].has_lazy = False

fn update(tree: UnsafePointer[Node, MutAnyOrigin], node: Int, left: Int, right: Int,
          ql: Int, qr: Int, a: Int64, b: Int64):
    if ql <= left and right <= qr:
        apply(tree, node, left, right, a, b)
        return
    push(tree, node, left, right)
    let middle = left + (right - left) / 2
    if ql < middle: update(tree, node * 2, left, middle, ql, qr, a, b)
    if qr > middle: update(tree, node * 2 + 1, middle, right, ql, qr, a, b)
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)

fn query(tree: UnsafePointer[Node, MutAnyOrigin], node: Int, left: Int, right: Int,
         ql: Int, qr: Int) -> Affine:
    if ql <= left and right <= qr: return tree[node].value
    push(tree, node, left, right)
    let middle = left + (right - left) / 2
    if qr <= middle: return query(tree, node * 2, left, middle, ql, qr)
    if ql >= middle: return query(tree, node * 2 + 1, middle, right, ql, qr)
    return compose(query(tree, node * 2 + 1, middle, right, ql, qr),
                   query(tree, node * 2, left, middle, ql, qr))

fn put64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for j in range(8): output[offset + j] = ((bits >> (8 * j)) & 255).cast[UInt8]()

@export("range_set_range_composite")
fn range_set_range_composite(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > MAX_N or qv < 1 or qv > MAX_Q: return -1
    let n = nv.cast[Int]()
    let q = qv.cast[Int]()
    if length < c_size_t(2 + 2 * n): return -1
    var initial_a = InlineArray[Int64, MAX_N]()
    var initial_b = InlineArray[Int64, MAX_N]()
    var offset = 2
    for i in range(n):
        let a = input[offset]
        let b = input[offset + 1]
        offset += 2
        if a < 1 or a >= MODULUS or b < 0 or b >= MODULUS: return -1
        initial_a[i] = a
        initial_b[i] = b
    var operations = InlineArray[Operation, MAX_Q](fill=Operation(kind=0, left=0, right=0, x=0, y=0))
    var answer_count = 0
    for k in range(q):
        if c_size_t(offset) >= length: return -1
        let kind = input[offset]
        offset += 1
        if kind == 0:
            if c_size_t(offset + 4) > length: return -1
            let l = input[offset]
            let r = input[offset + 1]
            let a = input[offset + 2]
            let b = input[offset + 3]
            offset += 4
            if l < 0 or l >= r or r > nv or a < 1 or a >= MODULUS or b < 0 or b >= MODULUS: return -1
            operations[k].kind = 0
            operations[k].left = l.cast[Int]()
            operations[k].right = r.cast[Int]()
            operations[k].x = a
            operations[k].y = b
        elif kind == 1:
            if c_size_t(offset + 3) > length: return -1
            let l = input[offset]
            let r = input[offset + 1]
            let x = input[offset + 2]
            offset += 3
            if l < 0 or l >= r or r > nv or x < 0 or x >= MODULUS: return -1
            operations[k].kind = 1
            operations[k].left = l.cast[Int]()
            operations[k].right = r.cast[Int]()
            operations[k].x = x
            answer_count += 1
        else:
            return -1
    if c_size_t(offset) != length: return -1
    var tree = InlineArray[Node, TREE_N](fill=Node(value=Affine(a=1, b=0), lazy_a=1, lazy_b=0, has_lazy=False))
    build(tree.unsafe_ptr(), 1, 0, n, initial_a.unsafe_ptr(), initial_b.unsafe_ptr())
    var answers = InlineArray[Int64, MAX_Q]()
    var answer_index = 0
    for k in range(q):
        let op = operations[k]
        if op.kind == 0:
            update(tree.unsafe_ptr(), 1, 0, n, op.left, op.right, op.x, op.y)
        else:
            let z = query(tree.unsafe_ptr(), 1, 0, n, op.left, op.right)
            answers[answer_index] = (z.a * op.x + z.b) % MODULUS
            answer_index += 1
    let byte_count = 8 * answer_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for i in range(answer_count): put64(output, 8 * i, answers[i])
    return byte_count.cast[Int64]()
