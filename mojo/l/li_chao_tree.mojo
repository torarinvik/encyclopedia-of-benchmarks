from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("li_chao_tree")
fn li_chao_tree(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1537: return -1
    let count64 = values[0]
    if count64 < 0 or count64 > 512 or length != c_size_t(1 + 3 * count64): return -1
    var slope = InlineArray[Int64, 12289](fill=0)
    var intercept = InlineArray[Int64, 12289](fill=0)
    var left = InlineArray[Int, 12289](fill=-1)
    var right = InlineArray[Int, 12289](fill=-1)
    var used = 0
    var queries: Int64 = 0
    var checksum: Int64 = 0
    for operation in range(Int(count64)):
        let opcode = values[1 + 3 * operation]
        let first = values[2 + 3 * operation]
        let second = values[3 + 3 * operation]
        if opcode == 0:
            if first < -1000 or first > 1000 or second < -1000 or second > 1000: return -1
            if used == 0:
                slope[0] = first
                intercept[0] = second
                used = 1
                continue
            var a = first
            var b = second
            var node = 0
            var low: Int64 = -1000000
            var high: Int64 = 1000000
            while True:
                let middle = low + (high - low) // 2
                if a * middle + b < slope[node] * middle + intercept[node]:
                    let old_a = slope[node]
                    let old_b = intercept[node]
                    slope[node] = a
                    intercept[node] = b
                    a = old_a
                    b = old_b
                if low == high: break
                var child = -1
                var go_left = False
                if a * low + b < slope[node] * low + intercept[node]:
                    go_left = True
                    child = left[node]
                    high = middle
                elif a * high + b < slope[node] * high + intercept[node]:
                    child = right[node]
                    low = middle + 1
                else:
                    break
                if child < 0:
                    if used >= 12289: return -1
                    child = used
                    used += 1
                    if go_left: left[node] = child
                    else: right[node] = child
                    slope[child] = a
                    intercept[child] = b
                    break
                node = child
        elif opcode == 1:
            if first < -1000000 or first > 1000000 or second != 0 or used == 0: return -1
            var node = 0
            var low: Int64 = -1000000
            var high: Int64 = 1000000
            var best = slope[0] * first + intercept[0]
            while node >= 0:
                let candidate = slope[node] * first + intercept[node]
                if candidate < best: best = candidate
                if low == high: break
                let middle = low + (high - low) // 2
                if first <= middle:
                    node = left[node]
                    high = middle
                else:
                    node = right[node]
                    low = middle + 1
            queries += 1
            checksum += queries * (best + 1000001001)
        else:
            return -1
    return checksum
