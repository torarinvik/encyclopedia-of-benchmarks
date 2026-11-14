# Bounded recursive square-root decomposition for inclusive range minima.
# Algorithm attribution and CC BY-SA 4.0 terms: benchmarks/s/sqrt_tree/LICENSE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("sqrt_tree")
fn sqrt_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 770: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > 256 or qv < 0 or qv > 256: return -1
    let n = Int(nv)
    let q = Int(qv)
    if length != c_size_t(2+n+2*q): return -1
    for i in range(n):
        if input[2+i] < -1000000000 or input[2+i] > 1000000000: return -1
    for i in range(q):
        let left = input[2+n+2*i]
        let right = input[3+n+2*i]
        if left < 0 or right < left or right >= nv: return -1
    if capacity < c_size_t(8*q) or (q != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2

    var lefts = List[Int](capacity=512)
    var rights = List[Int](capacity=512)
    var depths = List[Int](capacity=512)
    var value_offsets = List[Int](capacity=512)
    var between_offsets = List[Int](capacity=512)
    var widths = List[Int](capacity=512)
    var blocks = List[Int](capacity=512)
    var child_starts = List[Int](capacity=512)
    var children = List[Int](capacity=512)
    for _ in range(512):
        lefts.append(0); rights.append(0); depths.append(0)
        value_offsets.append(0); between_offsets.append(0)
        widths.append(0); blocks.append(0); child_starts.append(0); children.append(0)
    var prefix = List[Int64](capacity=4096)
    var suffix = List[Int64](capacity=4096)
    var between = List[Int64](capacity=8192)
    for _ in range(4096):
        prefix.append(0); suffix.append(0)
    for _ in range(8192): between.append(0)
    var used_values = List[Int](capacity=16)
    var used_between = List[Int](capacity=16)
    for _ in range(16):
        used_values.append(0); used_between.append(0)
    lefts[0] = 0
    rights[0] = n
    var node_count = 1
    var child_count = 0
    var node = 0
    while node < node_count:
        let lo = lefts[node]
        let hi = rights[node]
        let depth = depths[node]
        let count = hi-lo
        if count > 2:
            var width = 1
            while width*width < count: width += 1
            let block_count = (count+width-1)//width
            let vo = used_values[depth]
            let bo = used_between[depth]
            used_values[depth] += count
            used_between[depth] += block_count*block_count
            value_offsets[node] = vo
            between_offsets[node] = bo
            widths[node] = width
            blocks[node] = block_count
            var minima = List[Int64](capacity=256)
            for _ in range(256): minima.append(0)
            child_starts[node] = child_count
            for block in range(block_count):
                let start = lo+block*width
                let end = min(hi, start+width)
                prefix[depth*256+vo+start-lo] = input[2+start]
                for i in range(start+1, end):
                    let slot = depth*256+vo+i-lo
                    prefix[slot] = min(prefix[slot-1], input[2+i])
                suffix[depth*256+vo+end-1-lo] = input[2+end-1]
                var i = end-1
                while i > start:
                    let slot = depth*256+vo+i-1-lo
                    suffix[slot] = min(input[2+i-1], suffix[slot+1])
                    i -= 1
                minima[block] = prefix[depth*256+vo+end-1-lo]
                lefts[node_count] = start
                rights[node_count] = end
                depths[node_count] = depth+1
                children[child_count] = node_count
                child_count += 1
                node_count += 1
            for first in range(block_count):
                var aggregate = minima[first]
                for last in range(first, block_count):
                    aggregate = min(aggregate, minima[last])
                    between[depth*512+bo+first*block_count+last] = aggregate
        node += 1

    for query in range(q):
        let lo = Int(input[2+n+2*query])
        let hi = Int(input[3+n+2*query])
        var current = 0
        while rights[current]-lefts[current] > 2:
            let first = (lo-lefts[current])//widths[current]
            let last = (hi-lefts[current])//widths[current]
            if first != last: break
            current = children[child_starts[current]+first]
        var answer = input[2+lo]
        if rights[current]-lefts[current] <= 2:
            for i in range(lo+1, hi+1): answer = min(answer, input[2+i])
        else:
            let depth = depths[current]
            let first = (lo-lefts[current])//widths[current]
            let last = (hi-lefts[current])//widths[current]
            let vo = value_offsets[current]
            answer = suffix[depth*256+vo+lo-lefts[current]]
            if first+1 < last:
                let index = depth*512+between_offsets[current]+(first+1)*blocks[current]+last-1
                answer = min(answer, between[index])
            answer = min(answer, prefix[depth*256+vo+hi-lefts[current]])
        var bits = bitcast[UInt64](answer)
        for byte in range(8):
            output[8*query+byte] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(8*q)
