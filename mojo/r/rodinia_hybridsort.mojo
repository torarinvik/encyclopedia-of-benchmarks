# Bounded float histogram scatter and per-bucket merge sort.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn hybrid_bucket(value: Int64, minimum: Float32, span: Float32) -> Int:
    let scaled = Float32(value)/Float32(1000000.0)
    var index = Int(((scaled-minimum)/span)*Float32(1024.0))
    if index < 0: index = 0
    if index > 1023: index = 1023
    return index

@export("rodinia_hybridsort")
fn rodinia_hybridsort(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 65: return -1
    let nv = input[0]
    if nv < 2 or nv > 64 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    var values = List[Int64](capacity=n)
    var scattered = List[Int64](capacity=n)
    var scratch = List[Int64](capacity=n)
    var minimum = Int64(1000001)
    var maximum = Int64(-1)
    for i in range(n):
        let value = input[i+1]
        if value < 0 or value > 1000000 or value%1000 != 0: return -1
        if value < minimum: minimum = value
        if value > maximum: maximum = value
        values.append(value); scattered.append(0); scratch.append(0)
    if minimum == maximum: return -1
    let min_f = Float32(minimum)/Float32(1000000.0)
    let max_f = Float32(maximum)/Float32(1000000.0)
    let span = max_f-min_f
    var histogram = List[Int](capacity=1024)
    var offsets = List[Int](capacity=1025)
    var next = List[Int](capacity=1024)
    for _ in range(1024): histogram.append(0); next.append(0)
    for _ in range(1025): offsets.append(0)
    for i in range(n): histogram[hybrid_bucket(values[i],min_f,span)] += 1
    for b in range(1024):
        offsets[b+1] = offsets[b]+histogram[b]
        next[b] = offsets[b]
    for i in range(n):
        let b = hybrid_bucket(values[i],min_f,span)
        scattered[next[b]] = values[i]
        next[b] += 1
    for b in range(1024):
        let start = offsets[b]
        let end = offsets[b+1]
        var width = 1
        while width < end-start:
            var left = start
            while left < end:
                var middle = left+width
                var right = left+2*width
                if middle > end: middle = end
                if right > end: right = end
                var a = left; var z = middle; var out = left
                while a < middle and z < right:
                    if scattered[a] <= scattered[z]:
                        scratch[out] = scattered[a]; a += 1
                    else:
                        scratch[out] = scattered[z]; z += 1
                    out += 1
                while a < middle:
                    scratch[out] = scattered[a]; a += 1; out += 1
                while z < right:
                    scratch[out] = scattered[z]; z += 1; out += 1
                left += 2*width
            for i in range(start,end): scattered[i] = scratch[i]
            width *= 2
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        for byte in range(8): output[8*i+byte] = UInt8((scattered[i] >> (8*byte)) & 255)
    return Int64(bytes)
