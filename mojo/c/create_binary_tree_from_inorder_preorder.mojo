from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("create_binary_tree_from_inorder_preorder")
fn create_binary_tree_from_inorder_preorder(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 127: return -1
    let n = values[0]
    if n < 0 or n > 63 or length != 1 + 2 * n: return -1
    var left = InlineArray[Int64, 63](-1)
    var right = InlineArray[Int64, 63](-1)
    for i in range(n):
        let pre = values[1 + i]
        let ino = values[1 + n + i]
        if pre < -2147483648 or pre > 2147483647 or ino < -2147483648 or ino > 2147483647: return -1
        for j in range(i):
            if values[1 + j] == pre or values[1 + n + j] == ino: return -1
        var matches: Int64 = 0
        for j in range(n):
            if values[1 + n + j] == pre: matches += 1
        if matches != 1: return -1
    var task_pre = InlineArray[Int64, 63](0)
    var task_in = InlineArray[Int64, 63](0)
    var task_size = InlineArray[Int64, 63](0)
    var tasks: Int64 = 0
    if n > 0:
        task_pre[0] = 0
        task_in[0] = 0
        task_size[0] = n
        tasks = 1
    while tasks > 0:
        tasks -= 1
        let ps = task_pre[tasks]
        let ins = task_in[tasks]
        let size = task_size[tasks]
        if size <= 0 or ps < 0 or ins < 0 or ps + size > n or ins + size > n: return -1
        var root = -1
        for j in range(ins, ins + size):
            if values[1 + n + j] == values[1 + ps]: root = j
        if root < 0: return -1
        let left_size = root - ins
        let right_size = size - left_size - 1
        if left_size > 0: left[ps] = ps + 1
        if right_size > 0: right[ps] = ps + left_size + 1
        if right_size > 0:
            task_pre[tasks] = ps + left_size + 1
            task_in[tasks] = root + 1
            task_size[tasks] = right_size
            tasks += 1
        if left_size > 0:
            task_pre[tasks] = ps + 1
            task_in[tasks] = ins
            task_size[tasks] = left_size
            tasks += 1
    let required = 6 * n + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var stage = InlineArray[UInt8, 379](0)
    var pending = InlineArray[Int64, 127](0)
    var top: Int64 = 0
    pending[0] = 0 if n > 0 else -1
    top = 1
    var written: Int64 = 0
    while top > 0:
        top -= 1
        let node = pending[top]
        if node < 0:
            stage[written] = 0
            written += 1
        else:
            let value = Int32(values[1 + node])
            let bits = UInt32(value)
            stage[written] = 1
            written += 1
            for b in range(4):
                stage[written] = UInt8((bits >> (8 * b)) & 255)
                written += 1
            pending[top] = right[node]
            top += 1
            pending[top] = left[node]
            top += 1
    for i in range(written): output[i] = stage[i]
    return n
