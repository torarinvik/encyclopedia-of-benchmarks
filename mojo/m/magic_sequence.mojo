from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn magic_sequence_hash_byte(hash: UInt64, byte: UInt8) -> UInt64:
    return (hash ^ UInt64(byte)) * UInt64(1099511628211)

@export("magic_sequence")
fn magic_sequence(v: UnsafePointer[Int64, ImmutAnyOrigin], n_values: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n_values != 1 or v[0] < 0 or v[0] > 11: return -1
    let n = Int(v[0])
    var vector = InlineArray[UInt8, 11](fill=0)
    var frequencies = InlineArray[UInt8, 11](fill=0)
    var next_candidate = InlineArray[UInt8, 11](fill=0)
    var prefix_sum = InlineArray[UInt8, 12](fill=0)
    var rows = InlineArray[UInt8, 4096](fill=0)
    var depth = 0; var solution_count = 0; var row_bytes = 0
    if n == 0:
        solution_count = 1
    else:
        while True:
            if depth == n:
                var is_magic = True
                for symbol in range(n):
                    if frequencies[symbol] != vector[symbol]: is_magic = False
                if is_magic:
                    solution_count += 1
                    for i in range(n): rows[row_bytes] = vector[i]; row_bytes += 1
                depth -= 1
                frequencies[Int(vector[depth])] -= 1
                continue
            let candidate = Int(next_candidate[depth])
            if candidate >= n:
                next_candidate[depth] = 0
                if depth == 0: break
                depth -= 1
                frequencies[Int(vector[depth])] -= 1
                continue
            next_candidate[depth] = UInt8(candidate + 1)
            let sum = Int(prefix_sum[depth]) + candidate
            if sum > n: continue
            vector[depth] = UInt8(candidate)
            frequencies[candidate] += 1
            prefix_sum[depth + 1] = UInt8(sum)
            depth += 1
            next_candidate[depth] = 0
    var hash: UInt64 = 14695981039346656037
    hash = magic_sequence_hash_byte(hash, UInt8(n))
    for shift in range(4): hash = magic_sequence_hash_byte(hash, UInt8((solution_count >> (shift * 8)) & 255))
    for i in range(row_bytes): hash = magic_sequence_hash_byte(hash, rows[i])
    return Int64(hash & UInt64(0x7fffffffffffffff))
