from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn shootout_lists_pass() -> Bool:
    var values = List[Int](length=203, fill=0)
    var next = List[Int](length=203, fill=0)
    var prev = List[Int](length=203, fill=0)
    for head in (0, 101):
        let base = head + 1
        values[head] = 100
        next[head] = base
        prev[head] = base + 99
        for offset in range(100):
            let item = base + offset
            values[item] = offset + 1
            if offset == 0: prev[item] = head
            else: prev[item] = item - 1
            if offset == 99: next[item] = head
            else: next[item] = item + 1
    next[202] = 202
    prev[202] = 202
    var a = next[0]
    var b = next[101]
    while a != 0 and b != 101:
        if values[a] != values[b]: return False
        a = next[a]
        b = next[b]
    if a != 0 or b != 101: return False
    while values[101] > 0:
        let item = next[101]
        let successor = next[item]
        next[101] = successor
        prev[successor] = 101
        values[101] -= 1
        let tail = prev[202]
        next[tail] = item
        next[item] = 202
        prev[202] = item
        prev[item] = tail
        values[202] += 1
    while values[202] > 0:
        let item = prev[202]
        let predecessor = prev[item]
        prev[202] = predecessor
        next[predecessor] = 202
        values[202] -= 1
        let tail = prev[101]
        next[tail] = item
        next[item] = 101
        prev[101] = item
        prev[item] = tail
        values[101] += 1
    var current = 0
    while True:
        let old_next = next[current]
        next[current] = prev[current]
        prev[current] = old_next
        current = old_next
        if current == 0: break
    if values[next[0]] != 100 or values[prev[0]] != 1: return False
    if values[next[101]] != 100 or values[prev[101]] != 1: return False
    if values[0] != 100 or values[101] != 100 or values[202] != 0: return False
    a = next[0]
    b = next[101]
    while a != 0 and b != 101:
        if values[a] != values[b]: return False
        a = next[a]
        b = next[b]
    return a == 0 and b == 101

@export("shootout_lists")
fn shootout_lists(runs: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if runs < 0 or runs > 10000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var size = 2
    if runs > 0: size = 4
    if capacity < c_size_t(size): return -2
    for _ in range(Int(runs)):
        if not shootout_lists_pass(): return -1
    if runs > 0:
        output[0] = 49
        output[1] = 48
        output[2] = 48
        output[3] = 10
    else:
        output[0] = 48
        output[1] = 10
    return Int64(size)
