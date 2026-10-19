from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fibheap_remove(inout left: InlineArray[Int64, 128], inout right: InlineArray[Int64, 128], x: Int64):
    left[right[x]] = left[x]
    right[left[x]] = right[x]

fn fibheap_add_root(keys: InlineArray[Int64, 128], inout parent: InlineArray[Int64, 128], inout left: InlineArray[Int64, 128], inout right: InlineArray[Int64, 128], inout minimum: Int64, x: Int64):
    parent[x] = -1
    if minimum == -1:
        left[x] = x
        right[x] = x
        minimum = x
    else:
        let m = minimum
        let r = right[m]
        left[x] = m
        right[x] = r
        right[m] = x
        left[r] = x
        if keys[x] < keys[m]: minimum = x

fn fibheap_link(inout parent: InlineArray[Int64, 128], inout child: InlineArray[Int64, 128], inout left: InlineArray[Int64, 128], inout right: InlineArray[Int64, 128], inout degree: InlineArray[Int64, 128], p: Int64, c: Int64):
    fibheap_remove(left, right, c)
    parent[c] = p
    if child[p] == -1:
        left[c] = c
        right[c] = c
        child[p] = c
    else:
        let first = child[p]
        let r = right[first]
        left[c] = first
        right[c] = r
        right[first] = c
        left[r] = c
    degree[p] += 1

fn fibheap_consolidate(keys: InlineArray[Int64, 128], inout parent: InlineArray[Int64, 128], inout child: InlineArray[Int64, 128], inout left: InlineArray[Int64, 128], inout right: InlineArray[Int64, 128], inout degree: InlineArray[Int64, 128], inout minimum: Int64):
    if minimum == -1: return
    var roots = InlineArray[Int64, 128](0)
    var count: Int64 = 0
    var x = minimum
    while True:
        roots[count] = x
        count += 1
        x = right[x]
        if x == minimum: break
    var by_degree = InlineArray[Int64, 129](-1)
    for i in range(count):
        x = roots[i]
        if parent[x] != -1: continue
        var d = degree[x]
        while by_degree[d] != -1:
            var y = by_degree[d]
            if keys[y] < keys[x]:
                let temp = x
                x = y
                y = temp
            by_degree[d] = -1
            fibheap_link(parent, child, left, right, degree, x, y)
            d = degree[x]
        by_degree[d] = x
    minimum = -1
    for d in range(129):
        if by_degree[d] != -1: fibheap_add_root(keys, parent, left, right, minimum, by_degree[d])

@export("fibonacci_heap")
fn fibonacci_heap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 128 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if input[i] < -2147483648 or input[i] > 2147483647: return -1
    let bytes = length * 8
    if capacity < bytes or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var keys = InlineArray[Int64, 128](0)
    var parent = InlineArray[Int64, 128](-1)
    var child = InlineArray[Int64, 128](-1)
    var left = InlineArray[Int64, 128](0)
    var right = InlineArray[Int64, 128](0)
    var degree = InlineArray[Int64, 128](0)
    var minimum: Int64 = -1
    for i in range(length):
        keys[i] = input[i]
        parent[i] = -1
        child[i] = -1
        degree[i] = 0
        left[i] = i
        right[i] = i
        fibheap_add_root(keys, parent, left, right, minimum, i)
    var stage = InlineArray[Int64, 128](0)
    for out_index in range(length):
        let z = minimum
        stage[out_index] = keys[z]
        if child[z] != -1:
            var children = InlineArray[Int64, 128](0)
            var child_count: Int64 = 0
            var c = child[z]
            while True:
                children[child_count] = c
                child_count += 1
                c = right[c]
                if c == child[z]: break
            for j in range(child_count): fibheap_add_root(keys, parent, left, right, minimum, children[j])
        fibheap_remove(left, right, z)
        if right[z] == z: minimum = -1
        else:
            minimum = right[z]
            fibheap_consolidate(keys, parent, child, left, right, degree, minimum)
    for i in range(length):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
