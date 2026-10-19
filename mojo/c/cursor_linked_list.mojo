from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cursor_linked_list")
fn cursor_linked_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 64: return -1
    let ops = input[0]
    if length != 1 + 2 * ops: return -1
    var elements = InlineArray[Int64, 100](0)
    var next = InlineArray[Int64, 100](0)
    var occupied = InlineArray[Bool, 100](False)
    for i in range(100): next[i] = i + 1
    next[99] = 0
    var head: Int64 = -1
    var count: Int64 = 0
    var query_found = InlineArray[Int64, 64](0)
    var query_values = InlineArray[Int64, 64](0)
    var query_count: Int64 = 0
    for oi in range(ops):
        let op = input[1 + 2 * oi]
        let arg = input[2 + 2 * oi]
        if op < 0 or op > 4 or arg < -2147483648 or arg > 2147483647: return -1
        if op == 0:
            let node = next[0]
            if node == 0: return -1
            next[0] = next[node]
            elements[node] = arg
            occupied[node] = True
            if head == -1: head = node
            else:
                var tail = head
                while next[tail] != -1: tail = next[tail]
                next[tail] = node
            next[node] = -1
            count += 1
        elif op == 1:
            if head == -1: return -1
            var prev: Int64 = -1
            var cur = head
            while cur != -1 and (not occupied[cur] or elements[cur] != arg):
                prev = cur
                cur = next[cur]
            if cur == -1: return -1
            let succ = next[cur]
            if prev == -1: head = succ
            else: next[prev] = succ
            let free_head = next[0]
            occupied[cur] = False
            elements[cur] = 0
            next[cur] = free_head
            next[0] = cur
            count -= 1
        elif op == 2:
            if arg < 0 or arg >= count: return -1
            var cur = head
            for j in range(arg): cur = next[cur]
            let target = elements[cur]
            var prev: Int64 = -1
            cur = head
            while cur != -1 and (not occupied[cur] or elements[cur] != target):
                prev = cur
                cur = next[cur]
            if cur == -1: return -1
            let succ = next[cur]
            if prev == -1: head = succ
            else: next[prev] = succ
            let free_head = next[0]
            occupied[cur] = False
            elements[cur] = 0
            next[cur] = free_head
            next[0] = cur
            count -= 1
        elif op == 3:
            if arg >= 0 and arg < count:
                var cur = head
                for j in range(arg): cur = next[cur]
                query_found[query_count] = 1
                query_values[query_count] = elements[cur]
            else:
                query_found[query_count] = 0
                query_values[query_count] = 0
            query_count += 1
        else:
            var cur = head
            var logical: Int64 = 0
            while cur != -1 and (not occupied[cur] or elements[cur] != arg):
                cur = next[cur]
                logical += 1
            if cur != -1:
                query_found[query_count] = 1
                query_values[query_count] = logical
            else:
                query_found[query_count] = 0
                query_values[query_count] = 0
            query_count += 1
    let fields = 1 + 2 * query_count + 2 + 300
    let bytes = fields * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var stage = InlineArray[Int64, 5000](0)
    var f: Int64 = 0
    stage[f] = query_count; f += 1
    for i in range(query_count):
        stage[f] = query_found[i]; f += 1
        stage[f] = query_values[i]; f += 1
    stage[f] = head; f += 1
    stage[f] = count; f += 1
    for i in range(100):
        stage[f] = 1 if occupied[i] else 0; f += 1
        stage[f] = elements[i]; f += 1
        stage[f] = next[i]; f += 1
    for i in range(fields):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
