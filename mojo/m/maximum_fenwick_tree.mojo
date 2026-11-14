from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("maximum_fenwick_tree")
fn maximum_fenwick_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 194:
        return -1
    if input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 64:
        return -1
    let size = Int(input[0])
    let count = Int(input[1])
    if Int(length) != 2 + 3 * count:
        return -1
    var values = InlineArray[Int64, 64](fill=0)
    var tree = InlineArray[Int64, 64](fill=0)
    var answers = InlineArray[Int64, 64](fill=0)
    var answer_count = 0
    for op in range(count):
        let pos = 2 + 3 * op
        let kind = input[pos]
        let a = input[pos + 1]
        let b = input[pos + 2]
        if kind == 0:
            if a < 0 or a >= Int64(size) or b < 0 or b > 2147483647:
                return -1
            var index = Int(a)
            let old_value = values[index]
            values[index] = b
            while index < size:
                let old_max = tree[index]
                if b > old_max:
                    tree[index] = b
                elif old_value == old_max:
                    let left = index & (index + 1)
                    var maximum = b
                    var child = index - 1
                    while child >= left:
                        if tree[child] > maximum:
                            maximum = tree[child]
                        if maximum == old_max:
                            break
                        child = (child & (child + 1)) - 1
                    tree[index] = maximum
                    if maximum == old_max:
                        break
                else:
                    break
                index = index | (index + 1)
        elif kind == 1:
            if a < 0 or a > b or b > Int64(size):
                return -1
            var maximum: Int64 = 0
            var right = Int(b) - 1
            while Int64(right) >= a:
                let left = right & (right + 1)
                if Int64(left) >= a:
                    if tree[right] > maximum:
                        maximum = tree[right]
                    right = left - 1
                else:
                    if values[right] > maximum:
                        maximum = values[right]
                    right -= 1
            answers[answer_count] = maximum
            answer_count += 1
        else:
            return -1
    let byte_count = answer_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    for i in range(answer_count):
        let bits = UInt64(answers[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(byte_count)
