from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn cpp_avl_height(root: Int, left: List[Int], right: List[Int]) -> Int:
    if root < 0: return 0
    return 1 + max(cpp_avl_height(left[root], left, right), cpp_avl_height(right[root], left, right))

fn cpp_avl_rotate_right(root: Int, mut left: List[Int], mut right: List[Int]) -> Int:
    let pivot = left[root]
    let moved = right[pivot]
    right[pivot] = root
    left[root] = moved
    return pivot

fn cpp_avl_rotate_left(root: Int, mut left: List[Int], mut right: List[Int]) -> Int:
    let pivot = right[root]
    let moved = left[pivot]
    left[pivot] = root
    right[root] = moved
    return pivot

fn cpp_avl_insert(root: Int, key: Int64, mut keys: List[Int64], mut left: List[Int], mut right: List[Int], mut next: Int) -> Int:
    if root < 0:
        let node = next
        next += 1
        keys[node] = key
        left[node] = -1
        right[node] = -1
        return node
    if key < keys[root]: left[root] = cpp_avl_insert(left[root], key, keys, left, right, next)
    else: right[root] = cpp_avl_insert(right[root], key, keys, left, right, next)
    let balance = cpp_avl_height(left[root], left, right) - cpp_avl_height(right[root], left, right)
    if balance > 1:
        if cpp_avl_height(right[left[root]], left, right) > cpp_avl_height(left[left[root]], left, right): left[root] = cpp_avl_rotate_left(left[root], left, right)
        return cpp_avl_rotate_right(root, left, right)
    if balance < -1:
        if cpp_avl_height(left[right[root]], left, right) > cpp_avl_height(right[right[root]], left, right): right[root] = cpp_avl_rotate_right(right[root], left, right)
        return cpp_avl_rotate_left(root, left, right)
    return root

fn cpp_avl_emit(root: Int, keys: List[Int64], left: List[Int], right: List[Int], output: UnsafePointer[UInt8, MutAnyOrigin], mut position: Int):
    if root < 0: return
    cpp_avl_emit(left[root], keys, left, right, output, position)
    let bits = UInt32(keys[root])
    for b in range(4): output[position * 4 + b] = UInt8((bits >> UInt(8 * b)) & 255)
    position += 1
    cpp_avl_emit(right[root], keys, left, right, output, position)

@export("avltree_cpp_insert_only")
fn avltree_cpp_insert_only(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257 or input[0] < 1 or input[0] > 256: return -1
    let count = Int(input[0])
    if length != c_size_t(count + 1): return -1
    for i in range(count):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647: return -1
        for j in range(i):
            if input[i + 1] == input[j + 1]: return -1
    let bytes = count * 4
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var keys = List[Int64](length=256, fill=0)
    var left = List[Int](length=256, fill=-1)
    var right = List[Int](length=256, fill=-1)
    var next = 0
    var root = -1
    for i in range(count): root = cpp_avl_insert(root, input[i + 1], keys, left, right, next)
    var position = 0
    cpp_avl_emit(root, keys, left, right, output, position)
    return Int64(bytes)
