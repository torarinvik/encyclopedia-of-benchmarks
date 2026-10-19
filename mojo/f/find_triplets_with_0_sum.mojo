from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("find_triplets_with_0_sum")
fn find_triplets_with_0_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 64 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var values = InlineArray[Int64, 64](0)
    for i in range(length):
        if input[i] < -100000 or input[i] > 100000: return -1
        values[i] = input[i]
    for i in range(1, length):
        let key = values[i]
        var j = i
        while j > 0 and values[j - 1] > key:
            values[j] = values[j - 1]
            j -= 1
        values[j] = key
    var count: Int64 = 0
    var has_last = False
    var last_a: Int64 = 0
    var last_b: Int64 = 0
    var last_c: Int64 = 0
    for i in range(length):
        if i + 2 >= length: break
        for j in range(i + 1, length):
            if j + 1 >= length: break
            for k in range(j + 1, length):
                if values[i] + values[j] + values[k] != 0: continue
                if has_last and values[i] == last_a and values[j] == last_b and values[k] == last_c: continue
                count += 1
                last_a = values[i]
                last_b = values[j]
                last_c = values[k]
                has_last = True
    if count == 0: return 0
    let bytes = count * 12
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < bytes: return -2
    var out: Int64 = 0
    has_last = False
    last_a = 0; last_b = 0; last_c = 0
    for i in range(length):
        if i + 2 >= length: break
        for j in range(i + 1, length):
            if j + 1 >= length: break
            for k in range(j + 1, length):
                if values[i] + values[j] + values[k] != 0: continue
                if has_last and values[i] == last_a and values[j] == last_b and values[k] == last_c: continue
                let a = UInt32(Int32(values[i]))
                let b = UInt32(Int32(values[j]))
                let c = UInt32(Int32(values[k]))
                for byte in range(4): output[out * 12 + byte] = UInt8((a >> (8 * byte)) & 255)
                for byte in range(4): output[out * 12 + 4 + byte] = UInt8((b >> (8 * byte)) & 255)
                for byte in range(4): output[out * 12 + 8 + byte] = UInt8((c >> (8 * byte)) & 255)
                out += 1
                last_a=values[i]; last_b=values[j]; last_c=values[k]
                has_last = True
    return count
