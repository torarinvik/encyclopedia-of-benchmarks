from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("sparse_supernodal_cholesky")
fn sparse_supernodal_cholesky(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 56: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > input[0]: return -1
    let n = Int(input[0])
    let count = Int(input[1])
    let triangle = n * (n + 1) // 2
    if length != c_size_t(3 + count + n + triangle): return -1
    var boundaries = InlineArray[Int, 9](0)
    var masks = InlineArray[Int, 8](0)
    var slots = InlineArray[Int, 64](36)
    for i in range(count + 1):
        if input[2 + i] < 0 or input[2 + i] > Int64(n): return -1
        boundaries[i] = Int(input[2 + i])
        if i > 0 and boundaries[i] <= boundaries[i - 1]: return -1
    if boundaries[0] != 0 or boundaries[count] != n: return -1
    for row in range(n):
        let mask = input[3 + count + row]
        if mask < 0 or mask >= (Int64(1) << (row + 1)) or (mask & (Int64(1) << row)) == 0: return -1
        masks[row] = Int(mask)
    for col in range(n):
        for row in range(col + 1, n):
            if (masks[row] & (1 << col)) == 0: continue
            for lower in range(row + 1, n):
                if (masks[lower] & (1 << col)) != 0 and (masks[lower] & (1 << row)) == 0: return -1
    for block in range(count):
        let start = boundaries[block]
        let end = boundaries[block + 1]
        for row in range(start, end):
            for col in range(start, row):
                if (masks[row] & (1 << col)) == 0: return -1
        let bits = ((1 << end) - 1) ^ ((1 << start) - 1)
        for row in range(end, n):
            let selected = masks[row] & bits
            if selected != 0 and selected != bits: return -1
    var sparse = InlineArray[Float64, 36](0.0)
    var cursor = 3 + count + n
    var used = 0
    for row in range(n):
        for col in range(row + 1):
            let value = input[cursor]
            cursor += 1
            if value < -1000000 or value > 1000000: return -1
            if (masks[row] & (1 << col)) == 0:
                if value != 0: return -1
            else:
                slots[row * 8 + col] = used
                sparse[used] = Float64(value) / 1000.0
                used += 1
    for block in range(count):
        let start = boundaries[block]
        let end = boundaries[block + 1]
        for col in range(start, end):
            let pivot = sparse[slots[col * 8 + col]]
            let exponent = bitcast[UInt64](pivot) & UInt64(0x7ff0000000000000)
            if exponent == UInt64(0x7ff0000000000000) or pivot <= 0.0: return -1
            sparse[slots[col * 8 + col]] = sqrt(pivot)
            for row in range(col + 1, end):
                sparse[slots[row * 8 + col]] /= sparse[slots[col * 8 + col]]
            for row in range(col + 1, end):
                for target in range(col + 1, row + 1):
                    sparse[slots[row * 8 + target]] -= sparse[slots[row * 8 + col]] * sparse[slots[target * 8 + col]]
        for row in range(end, n):
            if (masks[row] & (1 << start)) == 0: continue
            for col in range(start, end):
                var value = sparse[slots[row * 8 + col]]
                for k in range(start, col): value -= sparse[slots[row * 8 + k]] * sparse[slots[col * 8 + k]]
                sparse[slots[row * 8 + col]] = value / sparse[slots[col * 8 + col]]
        for row in range(end, n):
            if (masks[row] & (1 << start)) == 0: continue
            for target in range(end, row + 1):
                if (masks[target] & (1 << start)) == 0: continue
                for k in range(start, end):
                    sparse[slots[row * 8 + target]] -= sparse[slots[row * 8 + k]] * sparse[slots[target * 8 + k]]
    let required = triangle * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var offset = 0
    for row in range(n):
        for col in range(row + 1):
            let slot = slots[row * 8 + col]
            var value: Float64 = 0.0
            if slot != 36: value = sparse[slot]
            let bits = bitcast[UInt64](value)
            for byte in range(8):
                output[offset] = UInt8((bits >> (byte * 8)) & 255)
                offset += 1
    return Int64(required)
