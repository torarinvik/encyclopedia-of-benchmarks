# One-lookahead LZ78 parser using dictionary phrases as input slices.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn flexible_equal(input: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, b: Int, size: Int) -> Bool:
    for i in range(size):
        if input[1+a+i] != input[1+b+i]: return False
    return True

@export("lz78_flexible_parsing")
fn lz78_flexible_parsing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34: return -1
    let nv = input[0]
    if nv < 0 or nv > 32 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    for i in range(n):
        if input[1+i] < 32 or input[1+i] > 126: return -1
    var starts = List[Int](capacity=n+1)
    var sizes = List[Int](capacity=n+1)
    var fields = List[Int64](capacity=2*n)
    starts.append(0)
    sizes.append(0)
    var position = 0
    while position < n:
        var terminal = -1
        for id in range(1, len(starts)):
            if sizes[id] == n-position and flexible_equal(input, starts[id], position, sizes[id]):
                terminal = id
                break
        if terminal >= 0:
            fields.append(Int64(terminal))
            fields.append(0)
            break
        var best_parent = -1
        var best_size = 0
        var best_score = -1
        var best_new = False
        for parent in range(len(starts)):
            let prefix = sizes[parent]
            if position + prefix >= n or not flexible_equal(input, starts[parent], position, prefix): continue
            let phrase_size = prefix + 1
            var is_new = True
            for id in range(1, len(starts)):
                if sizes[id] == phrase_size and flexible_equal(input, starts[id], position, phrase_size):
                    is_new = False
                    break
            let next_position = position + phrase_size
            var next_length = 0
            for id in range(1, len(starts)):
                let size = sizes[id]
                if size > next_length and next_position + size <= n and flexible_equal(input, starts[id], next_position, size): next_length = size
            if is_new and phrase_size > next_length and next_position + phrase_size <= n and flexible_equal(input, position, next_position, phrase_size):
                next_length = phrase_size
            let score = phrase_size + next_length
            if score > best_score or (score == best_score and phrase_size > best_size):
                best_parent = parent
                best_size = phrase_size
                best_score = score
                best_new = is_new
        if best_parent < 0: return -1
        fields.append(Int64(best_parent))
        fields.append(input[1+position+best_size-1])
        if best_new:
            starts.append(position)
            sizes.append(best_size)
        position += best_size
    let bytes = 8 * len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
