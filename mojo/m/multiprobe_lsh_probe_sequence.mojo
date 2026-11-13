from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mpls_key(mask: Int, distances: InlineArray[Int, 8], n: Int) -> Int:
    var score = 0
    var bits = 0
    for i in range(n):
        if mask & (1 << i) != 0:
            score += distances[i] * distances[i]
            bits += 1
    return score * 2304 + bits * 256 + mask

fn mpls_push(inout heap: InlineArray[Int, 256], size: Int, mask: Int,
             distances: InlineArray[Int, 8], n: Int) -> Int:
    var at = size
    let key = mpls_key(mask, distances, n)
    while at > 0 and key < mpls_key(heap[(at-1)//2], distances, n):
        heap[at] = heap[(at-1)//2]
        at = (at-1)//2
    heap[at] = mask
    return size + 1

fn mpls_pop(inout heap: InlineArray[Int, 256], size: Int,
            distances: InlineArray[Int, 8], n: Int) -> Int:
    let result = heap[0]
    let remaining = size - 1
    let last = heap[remaining]
    var at = 0
    while 2*at+1 < remaining:
        var child = 2*at+1
        if child+1 < remaining and mpls_key(heap[child+1], distances, n) < mpls_key(heap[child], distances, n): child += 1
        if mpls_key(heap[child], distances, n) >= mpls_key(last, distances, n): break
        heap[at] = heap[child]
        at = child
    if remaining > 0: heap[at] = last
    return result

@export("multiprobe_lsh_probe_sequence")
fn multiprobe_lsh_probe_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 7: return -1
    if input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 1000: return -1
    let m = Int(input[0])
    let width = Int(input[1])
    var limit = 1
    for _ in range(m): limit *= 3
    if length != c_size_t(3+m) or input[2] < 0 or input[2] >= Int64(limit): return -1
    let count = Int(input[2])
    var distances = InlineArray[Int, 8](fill=0)
    var coords = InlineArray[Int, 8](fill=0)
    var signs = InlineArray[Int, 8](fill=0)
    for i in range(m):
        if input[3+i] < 0 or input[3+i] > Int64(width): return -1
        distances[2*i] = Int(input[3+i])
        distances[2*i+1] = width - distances[2*i]
        coords[2*i] = i
        coords[2*i+1] = i
        signs[2*i] = -1
        signs[2*i+1] = 1
    for i in range(1, 2*m):
        let d = distances[i]
        let c = coords[i]
        let s = signs[i]
        var j = i
        while j > 0 and (distances[j-1] > d or (distances[j-1] == d and (coords[j-1] > c or (coords[j-1] == c and signs[j-1] > s)))):
            distances[j] = distances[j-1]
            coords[j] = coords[j-1]
            signs[j] = signs[j-1]
            j -= 1
        distances[j] = d
        coords[j] = c
        signs[j] = s
    var heap = InlineArray[Int, 256](fill=0)
    var size = mpls_push(heap, 0, 1, distances, 2*m)
    var result = InlineArray[UInt8, 80](fill=0)
    var emitted = 0
    while emitted < count:
        let mask = mpls_pop(heap, size, distances, 2*m)
        size -= 1
        var top = 0
        while (1 << (top+1)) <= mask: top += 1
        if top+1 < 2*m:
            size = mpls_push(heap, size, (mask ^ (1 << top)) | (1 << (top+1)), distances, 2*m)
            size = mpls_push(heap, size, mask | (1 << (top+1)), distances, 2*m)
        var seen = 0
        var valid = True
        for i in range(2*m):
            if mask & (1 << i) != 0:
                let bit = 1 << coords[i]
                if seen & bit != 0:
                    valid = False
                    break
                seen |= bit
        if valid:
            result[emitted] = UInt8(mask)
            emitted += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = result[i]
    return Int64(count)
