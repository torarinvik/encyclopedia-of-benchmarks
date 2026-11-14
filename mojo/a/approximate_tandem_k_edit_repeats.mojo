from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

fn edit_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, an: Int, b: Int, bn: Int) -> Int:
    var row = List[Int](capacity=13)
    for j in range(13): row.append(j)
    for i in range(1, an+1):
        var diagonal = row[0]
        row[0] = i
        for j in range(1, bn+1):
            let above = row[j]
            var substitute = diagonal
            if input[2+a+i-1] != input[2+b+j-1]: substitute += 1
            row[j] = min(above+1, min(row[j-1]+1, substitute))
            diagonal = above
    return row[bn]

fn minimum_cost(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, size: Int) -> Int:
    var starts = List[Int](capacity=12)
    var lengths = List[Int](capacity=12)
    for _ in range(12):
        starts.append(0)
        lengths.append(0)
    var best = 1000
    for prefix in range(size+1):
        for suffix in range(size-prefix+1):
            let middle = size-prefix-suffix
            if middle < 2: continue
            let end_mask = 1 << (middle-1)
            for mask in range(1, end_mask):
                var segments = 0
                var previous = 0
                for cut in range(1, middle):
                    if mask & (1 << (cut-1)) != 0:
                        starts[segments] = start+prefix+previous
                        lengths[segments] = cut-previous
                        segments += 1
                        previous = cut
                starts[segments] = start+prefix+previous
                lengths[segments] = middle-previous
                segments += 1
                var left = 1000
                for fragment in range(lengths[0]+1):
                    left = min(left, edit_distance(input, start, prefix, starts[0]+lengths[0]-fragment, fragment))
                let last = segments-1
                var right = 1000
                for fragment in range(lengths[last]+1):
                    right = min(right, edit_distance(input, starts[last], fragment, start+size-suffix, suffix))
                var internal = 0
                for i in range(last):
                    internal += edit_distance(input, starts[i], lengths[i], starts[i+1], lengths[i+1])
                best = min(best, left+internal+right)
    return best

@export("approximate_tandem_k_edit_repeats")
fn approximate_tandem_k_edit_repeats(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 14: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 2 or nv > 12 or kv < 0 or kv > 4: return -1
    let n = Int(nv)
    let budget = Int(kv)
    if length != c_size_t(n+2): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 3: return -1
    var count = 0
    for start in range(n):
        for size in range(2, n-start+1):
            if minimum_cost(input, start, size) <= budget: count += 1
    let bytes = 8*(1+3*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, Int64(count))
    var record = 0
    for start in range(n):
        for size in range(2, n-start+1):
            let cost = minimum_cost(input, start, size)
            if cost <= budget:
                let offset = 8*(1+3*record)
                put_word(output, offset, Int64(start))
                put_word(output, offset+8, Int64(size))
                put_word(output, offset+16, Int64(cost))
                record += 1
    return Int64(bytes)
