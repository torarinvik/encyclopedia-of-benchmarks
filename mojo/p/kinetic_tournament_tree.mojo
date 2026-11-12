from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime KTT_N = 8
comptime KTT_M = 32
comptime KTT_BASE = 8
comptime KTT_INPUT_MAX = 2 + 2 * KTT_N + 4 * KTT_M
comptime KTT_INF: Int64 = 1 << 60

struct KttNode:
    valid: Bool
    winner: Int
    best: Int64
    lazy: Int64
    deadline: Int64

struct KttOp:
    kind: Int64
    left: Int64
    right: Int64
    delta: Int64

fn ktt_pull(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    slope: InlineArray[Int64, KTT_N]):
    let left = 2 * node
    let right = left + 1
    if not tree[left].valid and not tree[right].valid:
        tree[node].valid = False
        tree[node].deadline = KTT_INF
        return
    if not tree[left].valid or not tree[right].valid:
        let child = right if tree[right].valid else left
        tree[node].valid = True
        tree[node].winner = tree[child].winner
        tree[node].best = tree[child].best
        tree[node].deadline = tree[child].deadline
        return
    let li = tree[left].winner
    let ri = tree[right].winner
    let choose_left = tree[left].best > tree[right].best or (tree[left].best == tree[right].best and slope[li] > slope[ri])
    let win = left if choose_left else right
    let lose = right if choose_left else left
    let wi = tree[win].winner
    let lo = tree[lose].winner
    var crossing = KTT_INF
    if slope[wi] < slope[lo]:
        let gap = tree[win].best - tree[lose].best
        let slope_gap = slope[lo] - slope[wi]
        crossing = 0 if gap <= 0 else (gap + slope_gap - 1) // slope_gap
    tree[node].valid = True
    tree[node].winner = wi
    tree[node].best = tree[win].best
    tree[node].deadline = min(crossing, min(tree[left].deadline, tree[right].deadline))

fn ktt_apply(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    slope: InlineArray[Int64, KTT_N], delta: Int64):
    if not tree[node].valid: return
    tree[node].best += slope[tree[node].winner] * delta
    tree[node].lazy += delta
    tree[node].deadline -= delta

fn ktt_push(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    slope: InlineArray[Int64, KTT_N]):
    let delta = tree[node].lazy
    if delta == 0 or node >= KTT_BASE: return
    ktt_apply(mut tree, 2 * node, slope, delta)
    ktt_apply(mut tree, 2 * node + 1, slope, delta)
    tree[node].lazy = 0

fn ktt_repair(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    slope: InlineArray[Int64, KTT_N]):
    if node >= KTT_BASE or not tree[node].valid: return
    ktt_push(mut tree, node, slope)
    if tree[2 * node].valid and tree[2 * node].deadline <= 0:
        ktt_repair(mut tree, 2 * node, slope)
    if tree[2 * node + 1].valid and tree[2 * node + 1].deadline <= 0:
        ktt_repair(mut tree, 2 * node + 1, slope)
    ktt_pull(mut tree, node, slope)

fn ktt_translate(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    lo: Int, hi: Int, ql: Int, qr: Int, delta: Int64,
    slope: InlineArray[Int64, KTT_N]):
    if ql <= lo and hi <= qr:
        ktt_apply(mut tree, node, slope, delta)
        ktt_repair(mut tree, node, slope)
        return
    ktt_push(mut tree, node, slope)
    let mid = (lo + hi) // 2
    if ql < mid: ktt_translate(mut tree, 2 * node, lo, mid, ql, qr, delta, slope)
    if mid < qr: ktt_translate(mut tree, 2 * node + 1, mid, hi, ql, qr, delta, slope)
    ktt_pull(mut tree, node, slope)

fn ktt_query(mut tree: InlineArray[KttNode, 2 * KTT_BASE], node: Int,
    lo: Int, hi: Int, ql: Int, qr: Int, slope: InlineArray[Int64, KTT_N]) -> Int64:
    if ql <= lo and hi <= qr: return tree[node].best
    ktt_push(mut tree, node, slope)
    let mid = (lo + hi) // 2
    var answer: Int64 = -9223372036854775807 - 1
    if ql < mid: answer = ktt_query(mut tree, 2 * node, lo, mid, ql, qr, slope)
    if mid < qr: answer = max(answer, ktt_query(mut tree, 2 * node + 1, mid, hi, ql, qr, slope))
    ktt_pull(mut tree, node, slope)
    return answer

fn ktt_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("kinetic_tournament_tree")
fn kinetic_tournament_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > KTT_INPUT_MAX:
        return -1
    let nr = input[0]
    let mr = input[1]
    if nr < 1 or nr > KTT_N or mr < 1 or mr > KTT_M: return -1
    let n = Int(nr)
    let m = Int(mr)
    var cursor = 2
    var slope = InlineArray[Int64, KTT_N](fill=0)
    var intercept = InlineArray[Int64, KTT_N](fill=0)
    for i in range(n):
        if cursor + 2 > Int(length): return -1
        slope[i] = input[cursor]
        intercept[i] = input[cursor + 1]
        cursor += 2
        if slope[i] < -8 or slope[i] > 8 or intercept[i] < -64 or intercept[i] > 64 or (i > 0 and slope[i] <= slope[i - 1]): return -1
    var operations = InlineArray[KttOp, KTT_M](fill=KttOp(0, 0, 0, 0))
    var query_count = 0
    for i in range(m):
        if cursor >= Int(length): return -1
        let kind = input[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 3 > Int(length): return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let delta = input[cursor + 2]
            cursor += 3
            if left < 0 or left > right or right >= nr or delta < 1 or delta > 8: return -1
            operations[i] = KttOp(kind, left, right, delta)
        elif kind == 1:
            if cursor + 2 > Int(length): return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            cursor += 2
            if left < 0 or left > right or right >= nr: return -1
            operations[i] = KttOp(kind, left, right, 0)
            query_count += 1
        else: return -1
    if cursor != Int(length) or query_count == 0: return -1
    let required = 8 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var tree = InlineArray[KttNode, 2 * KTT_BASE](fill=KttNode(False, 0, 0, 0, KTT_INF))
    for i in range(n):
        let node = KTT_BASE + i
        tree[node].valid = True
        tree[node].winner = i
        tree[node].best = intercept[i]
    for node in range(1, KTT_BASE): ktt_pull(mut tree, KTT_BASE - node, slope)
    var answers = InlineArray[Int64, KTT_M](fill=0)
    var answer_count = 0
    for i in range(m):
        let op = operations[i]
        if op.kind == 0:
            ktt_translate(mut tree, 1, 0, KTT_BASE, Int(op.left), Int(op.right) + 1, op.delta, slope)
        else:
            answers[answer_count] = ktt_query(mut tree, 1, 0, KTT_BASE, Int(op.left), Int(op.right) + 1, slope)
            answer_count += 1
    for i in range(answer_count): ktt_store(output, 8 * i, answers[i])
    return Int64(required)
