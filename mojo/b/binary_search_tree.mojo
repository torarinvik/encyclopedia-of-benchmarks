from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime NONE = 256

@export("binary_search_tree_benchmark")
fn binary_search_tree_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length % 2) != 0: return -1
    let operations = Int(length) // 2
    if operations > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var keys = List[Int64](capacity=256); var left = List[Int](capacity=256); var right = List[Int](capacity=256); var next_free = List[Int](capacity=256)
    for i in range(256): keys.append(0); left.append(NONE); right.append(NONE); next_free.append(i + 1)
    var free_head = 0; var root = NONE; var count = 0; var checksum: Int64 = 0
    for operation in range(operations):
        let opcode = input[2 * operation]; let payload = input[2 * operation + 1]
        var observed: Int64 = 0
        if opcode == 0:
            if payload < -1_000_000 or payload > 1_000_000: return -1
            var parent = NONE; var node = root
            while node != NONE and keys[node] != payload:
                parent = node
                node = left[node] if payload < keys[node] else right[node]
            if node == NONE:
                if count >= 256 or free_head == NONE: return -1
                node = free_head; free_head = next_free[node]; keys[node] = payload; left[node] = NONE; right[node] = NONE
                if parent == NONE: root = node
                elif payload < keys[parent]: left[parent] = node
                else: right[parent] = node
                count += 1; observed = 1
        elif opcode == 1:
            if payload < -1_000_000 or payload > 1_000_000: return -1
            var parent = NONE; var node = root
            while node != NONE and keys[node] != payload:
                parent = node
                node = left[node] if payload < keys[node] else right[node]
            observed = 1 if node != NONE else 0
            if node != NONE:
                if left[node] != NONE and right[node] != NONE:
                    var pred_parent = node; var pred = left[node]
                    while right[pred] != NONE: pred_parent = pred; pred = right[pred]
                    keys[node] = keys[pred]; parent = pred_parent; node = pred
                let child = left[node] if left[node] != NONE else right[node]
                if parent == NONE: root = child
                elif left[parent] == node: left[parent] = child
                else: right[parent] = child
                next_free[node] = free_head; free_head = node; count -= 1
        elif opcode == 2:
            if payload < -1_000_000 or payload > 1_000_000: return -1
            var node = root
            while node != NONE and keys[node] != payload: node = left[node] if payload < keys[node] else right[node]
            observed = 1 if node != NONE else 0
        elif opcode == 3 or opcode == 4:
            if payload != 0 or root == NONE: return -1
            var node = root
            if opcode == 3:
                while left[node] != NONE: node = left[node]
            else:
                while right[node] != NONE: node = right[node]
            observed = keys[node]
        elif opcode == 5:
            if payload != 0: return -1
            observed = Int64(count)
        else: return -1
        checksum += Int64(operation + 1) * (observed + 1_000_000)
    var stack = List[Int](capacity=256); var node = root; var index = 0
    while node != NONE or len(stack) > 0:
        while node != NONE: stack.append(node); node = left[node]
        node = stack.pop()
        checksum += Int64(operations + index + 1) * (keys[node] + 1_000_000)
        index += 1; node = right[node]
    return checksum
