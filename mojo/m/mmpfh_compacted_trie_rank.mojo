# Canonical preorder Patricia trie and delimiter rank queries.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mmpfh_compacted_trie_rank")
fn mmpfh_compacted_trie_rank(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 35: return -1
    let wv = input[0]
    let dv = input[1]
    let qv = input[2]
    if wv < 1 or wv > 16 or dv < 1 or dv > 16 or qv < 1 or qv > 16 or length != c_size_t(3+dv+qv): return -1
    let w = Int(wv)
    let d = Int(dv)
    let q = Int(qv)
    let limit = Int64(1 << w)
    var keys = List[Int](capacity=d)
    var queries = List[Int](capacity=q)
    for i in range(d):
        let key = input[3+i]
        if key < 0 or key >= limit or (i > 0 and key <= Int64(keys[i-1])): return -1
        keys.append(Int(key))
    for i in range(q):
        let key = input[3+d+i]
        if key < 0 or key >= limit: return -1
        queries.append(Int(key))
    var bits = List[Int](capacity=31)
    var left = List[Int](capacity=31)
    var right = List[Int](capacity=31)
    var lows = List[Int](capacity=31)
    var highs = List[Int](capacity=31)
    var leaves = List[Int](capacity=31)
    var stack_lo = List[Int](capacity=31)
    var stack_hi = List[Int](capacity=31)
    var stack_parent = List[Int](capacity=31)
    var stack_side = List[Int](capacity=31)
    stack_lo.append(0); stack_hi.append(d); stack_parent.append(-1); stack_side.append(0)
    var pending = 1
    while pending > 0:
        pending -= 1
        let lo = stack_lo[pending]
        let hi = stack_hi[pending]
        let parent = stack_parent[pending]
        let side = stack_side[pending]
        let node = len(bits)
        bits.append(-1); left.append(-1); right.append(-1)
        lows.append(keys[lo]); highs.append(keys[hi-1]); leaves.append(hi-lo)
        if parent >= 0:
            if side == 0: left[parent] = node
            else: right[parent] = node
        if hi-lo > 1:
            let diff = keys[lo] ^ keys[hi-1]
            var shift = w-1
            while (diff & (1 << shift)) == 0: shift -= 1
            bits[node] = w-1-shift
            var split = lo
            while (keys[split] & (1 << shift)) == 0: split += 1
            if pending < len(stack_lo):
                stack_lo[pending] = split; stack_hi[pending] = hi; stack_parent[pending] = node; stack_side[pending] = 1
            else:
                stack_lo.append(split); stack_hi.append(hi); stack_parent.append(node); stack_side.append(1)
            pending += 1
            if pending < len(stack_lo):
                stack_lo[pending] = lo; stack_hi[pending] = split; stack_parent[pending] = node; stack_side[pending] = 0
            else:
                stack_lo.append(lo); stack_hi.append(split); stack_parent.append(node); stack_side.append(0)
            pending += 1
    var fields = List[Int64](capacity=174)
    fields.append(dv); fields.append(Int64(len(bits))); fields.append(qv)
    for i in range(len(bits)):
        fields.append(Int64(bits[i])); fields.append(Int64(left[i])); fields.append(Int64(right[i]))
        fields.append(Int64(lows[i])); fields.append(Int64(highs[i]))
    for query in queries:
        var node = 0
        var rank = 0
        while True:
            if query < lows[node]: break
            if query > highs[node]:
                rank += leaves[node]
                break
            if bits[node] < 0: break
            if (query & (1 << (w-1-bits[node]))) != 0:
                rank += leaves[left[node]]
                node = right[node]
            else:
                node = left[node]
        fields.append(Int64(rank))
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
