from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn flash_class(value: Int64, minimum: Int64, span: Int64, classes: Int) -> Int:
    return Int((Int64(classes - 1) * (value - minimum)) / span)

fn flash_store_i32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt32(Int32(value))
    for b in range(4): output[offset + b] = UInt8((bits >> (8 * b)) & UInt32(255))

@export("flash_sort")
fn flash_sort(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 65 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let n = Int(length)
    if n == 2 or n > 64: return -1
    var values = InlineArray[Int64, 64](fill=0)
    for i in range(n):
        if input[i] < -1000000 or input[i] > 1000000: return -1
        values[i] = input[i]
    let bytes = n * 4
    if capacity < c_size_t(bytes) or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    if n > 1:
        var minimum = values[0]
        var maximum = values[0]
        for i in range(1, n):
            if values[i] < minimum: minimum = values[i]
            if values[i] > maximum: maximum = values[i]
        if minimum != maximum:
            let span = maximum - minimum
            var classes = (9 * n) // 20
            if classes < 1: classes = 1
            var ends = InlineArray[Int32, 64](fill=0)
            for i in range(n): ends[flash_class(values[i], minimum, span, classes)] += 1
            for i in range(1, classes): ends[i] += ends[i - 1]
            var moves = 0
            var j = 0
            var k = classes - 1
            while moves < n - 1:
                while j > Int(ends[k]) - 1:
                    j += 1
                    if j >= n: break
                    k = flash_class(values[j], minimum, span, classes)
                if j >= n: break
                var flash = values[j]
                while j != Int(ends[k]):
                    k = flash_class(flash, minimum, span, classes)
                    ends[k] -= 1
                    let target = Int(ends[k])
                    let held = values[target]
                    values[target] = flash
                    flash = held
                    moves += 1
            for i in range(1, n):
                let key = values[i]
                var cursor = i
                while cursor > 0 and values[cursor - 1] > key:
                    values[cursor] = values[cursor - 1]
                    cursor -= 1
                values[cursor] = key
    for i in range(n): flash_store_i32(output, i * 4, values[i])
    return Int64(bytes)
