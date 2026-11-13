from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime STMS_DOMAIN = 64
comptime STMS_MAX_Q = 32
comptime STMS_MAX_ROOTS = 33
comptime STMS_MAX_NODES = 1024
comptime STMS_MAX_INPUT = 131
comptime STMS_MAX_OUTPUT = 256

struct STMSNode(Copyable):
    var left: Int32
    var right: Int32
    var total: Int64

struct STMSOperation(Copyable):
    var op: Int64
    var a: Int64
    var b: Int64
    var c: Int64

fn stms_new_node(mut nodes: InlineArray[STMSNode, STMS_MAX_NODES], mut used: Int) -> Int:
    if used >= STMS_MAX_NODES: return -1
    let node = used
    used += 1
    nodes[node] = STMSNode(left=0, right=0, total=0)
    return node

fn stms_insert(mut nodes: InlineArray[STMSNode, STMS_MAX_NODES], mut used: Int,
        node_value: Int, lo: Int, hi: Int, value: Int, amount: Int64) -> Int:
    var node = node_value
    if node == 0:
        node = stms_new_node(mut nodes, mut used)
        if node < 0: return -1
    if lo == hi:
        nodes[node].total += amount
        return node
    let mid = (lo + hi) / 2
    if value <= mid:
        let child = stms_insert(mut nodes, mut used, Int(nodes[node].left), lo, mid, value, amount)
        if child < 0: return -1
        nodes[node].left = Int32(child)
    else:
        let child = stms_insert(mut nodes, mut used, Int(nodes[node].right), mid + 1, hi, value, amount)
        if child < 0: return -1
        nodes[node].right = Int32(child)
    nodes[node].total = nodes[Int(nodes[node].left)].total + nodes[Int(nodes[node].right)].total
    return node

fn stms_merge(mut nodes: InlineArray[STMSNode, STMS_MAX_NODES],
        a: Int, b: Int, lo: Int, hi: Int) -> Int:
    if a == 0: return b
    if b == 0: return a
    if lo == hi:
        nodes[a].total += nodes[b].total
        return a
    let mid = (lo + hi) / 2
    let al = Int(nodes[a].left)
    let ar = Int(nodes[a].right)
    let bl = Int(nodes[b].left)
    let br = Int(nodes[b].right)
    nodes[a].left = Int32(stms_merge(mut nodes, al, bl, lo, mid))
    nodes[a].right = Int32(stms_merge(mut nodes, ar, br, mid + 1, hi))
    nodes[a].total = nodes[Int(nodes[a].left)].total + nodes[Int(nodes[a].right)].total
    return a

fn stms_split(mut nodes: InlineArray[STMSNode, STMS_MAX_NODES], mut used: Int,
        node: Int, lo: Int, hi: Int, ql: Int, qr: Int,
        inout moved: Int) -> Int:
    moved = 0
    if node == 0 or qr < lo or hi < ql: return node
    if ql <= lo and hi <= qr:
        moved = node
        return 0
    let mid = (lo + hi) / 2
    var moved_left = 0
    var moved_right = 0
    let remain_left = stms_split(mut nodes, mut used, Int(nodes[node].left), lo, mid, ql, qr, moved_left)
    if remain_left < 0: return -1
    let remain_right = stms_split(mut nodes, mut used, Int(nodes[node].right), mid + 1, hi, ql, qr, moved_right)
    if remain_right < 0: return -1
    nodes[node].left = Int32(remain_left)
    nodes[node].right = Int32(remain_right)
    nodes[node].total = nodes[remain_left].total + nodes[remain_right].total
    if moved_left != 0 or moved_right != 0:
        moved = stms_new_node(mut nodes, mut used)
        if moved < 0: return -1
        nodes[moved].left = Int32(moved_left)
        nodes[moved].right = Int32(moved_right)
        nodes[moved].total = nodes[moved_left].total + nodes[moved_right].total
    return node

fn stms_range_sum(nodes: InlineArray[STMSNode, STMS_MAX_NODES], node: Int,
        lo: Int, hi: Int, ql: Int, qr: Int) -> Int64:
    if node == 0 or qr < lo or hi < ql: return 0
    if ql <= lo and hi <= qr: return nodes[node].total
    let mid = (lo + hi) / 2
    return stms_range_sum(nodes, Int(nodes[node].left), lo, mid, ql, qr) + stms_range_sum(
        nodes, Int(nodes[node].right), mid + 1, hi, ql, qr)

fn stms_kth(nodes: InlineArray[STMSNode, STMS_MAX_NODES], node: Int,
        lo: Int, hi: Int, k: Int64) -> Int64:
    if node == 0 or k > nodes[node].total: return -1
    if lo == hi: return Int64(lo)
    let mid = (lo + hi) / 2
    let left_node = Int(nodes[node].left)
    if k <= nodes[left_node].total:
        return stms_kth(nodes, left_node, lo, mid, k)
    return stms_kth(nodes, Int(nodes[node].right), mid + 1, hi, k - nodes[left_node].total)

fn stms_put_i64(mut output: InlineArray[UInt8, STMS_MAX_OUTPUT], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = ((bits >> (8 * byte)) & 255).cast[UInt8]()

@export("segment_tree_merge_split")
fn segment_tree_merge_split(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > STMS_MAX_INPUT:
        return -1
    if input[0] != STMS_DOMAIN or input[1] < 0 or input[1] > STMS_MAX_Q:
        return -1
    let q = Int(input[1])
    if length != c_size_t(2 + 4 * q): return -1
    var operations = InlineArray[STMSOperation, STMS_MAX_Q](fill=STMSOperation(op=0, a=0, b=0, c=0))
    var roots_count = 1
    for i in range(q):
        let base = 2 + 4 * i
        let op = input[base]
        let a = input[base + 1]
        let b = input[base + 2]
        let c = input[base + 3]
        let a_ok = a >= 0 and a < roots_count
        let b_ok = b >= 0 and b < roots_count
        var valid = False
        if op == 0:
            valid = a_ok and b >= 1 and b <= STMS_DOMAIN and c >= 1 and c <= 10
        elif op == 1:
            valid = a_ok and b >= 1 and b <= c and c <= STMS_DOMAIN and roots_count < STMS_MAX_ROOTS
            if valid: roots_count += 1
        elif op == 2:
            valid = a_ok and b_ok and a != b and c == 0
        elif op == 3:
            valid = a_ok and b >= 1 and b <= c and c <= STMS_DOMAIN
        elif op == 4:
            valid = a_ok and b >= 1 and b <= 320 and c == 0
        if not valid: return -1
        operations[i] = STMSOperation(op=op, a=a, b=b, c=c)

    var nodes = InlineArray[STMSNode, STMS_MAX_NODES](fill=STMSNode(left=0, right=0, total=0))
    var roots = InlineArray[Int32, STMS_MAX_ROOTS](fill=0)
    var staged = InlineArray[UInt8, STMS_MAX_OUTPUT](fill=0)
    var used = 1
    var root_count = 1
    var byte_count = 0
    for i in range(q):
        let item = operations[i]
        let a = Int(item.a)
        let b = Int(item.b)
        let c = Int(item.c)
        if item.op == 0:
            let updated = stms_insert(mut nodes, mut used, Int(roots[a]), 1, STMS_DOMAIN, b, item.c)
            if updated < 0: return -1
            roots[a] = Int32(updated)
        elif item.op == 1:
            var moved = 0
            let remain = stms_split(mut nodes, mut used, Int(roots[a]), 1, STMS_DOMAIN, b, c, moved)
            if remain < 0 or moved < 0: return -1
            roots[a] = Int32(remain)
            roots[root_count] = Int32(moved)
            root_count += 1
        elif item.op == 2:
            roots[a] = Int32(stms_merge(mut nodes, Int(roots[a]), Int(roots[b]), 1, STMS_DOMAIN))
            roots[b] = 0
        elif item.op == 3:
            let answer = stms_range_sum(nodes, Int(roots[a]), 1, STMS_DOMAIN, b, c)
            stms_put_i64(mut staged, byte_count, answer)
            byte_count += 8
        else:
            let answer = stms_kth(nodes, Int(roots[a]), 1, STMS_DOMAIN, item.b)
            stms_put_i64(mut staged, byte_count, answer)
            byte_count += 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    for i in range(byte_count): output[i] = staged[i]
    return Int64(byte_count)
