from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn lut_shift(mask: Int, nodes: Int, delay: Int) -> Int:
    var result = 0
    for bit in range(3 * nodes):
        if mask & (1 << bit) != 0:
            let shifted_delay = bit % 3 + delay
            if shifted_delay > 2: return -1
            result |= 1 << (3 * (bit // 3) + shifted_delay)
    return result

fn lut_popcount(mut value: Int) -> Int:
    var count = 0
    while value != 0:
        value &= value - 1
        count += 1
    return count

@export("sequential_lut_k_cut_enumeration")
fn sequential_lut_k_cut_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 12: return -1
    let n0 = input[0]; let k0 = input[1]; let m0 = input[2]
    if n0 < 1 or n0 > 3 or k0 < 1 or k0 > 2 or m0 < 0 or m0 > 3: return -1
    let n = Int(n0); let k = Int(k0); let m = Int(m0)
    if length != c_size_t(3 + 3 * m): return -1
    var sources = List[Int]()
    var targets = List[Int]()
    var delays = List[Int]()
    for edge in range(m):
        let u = input[3 + 3 * edge]; let v = input[4 + 3 * edge]; let d = input[5 + 3 * edge]
        if u < 0 or u >= v or v >= n0 or d < 0 or d > 1: return -1
        for prior in range(edge):
            if sources[prior] == Int(u) and targets[prior] == Int(v) and delays[prior] == Int(d): return -1
        sources.append(Int(u)); targets.append(Int(v)); delays.append(Int(d))
    var cuts = List[Int](length=135, fill=0)
    var counts = List[Int](length=3, fill=0)
    for v in range(n):
        var merged = List[Int]()
        merged.append(0)
        var degree = 0
        for edge in range(m):
            if targets[edge] == v:
                degree += 1
                var updated = List[Int]()
                for current in range(len(merged)):
                    for index in range(counts[sources[edge]]):
                        let shifted = lut_shift(cuts[45 * sources[edge] + index], n, delays[edge])
                        if shifted < 0: return -1
                        let candidate = merged[current] | shifted
                        if lut_popcount(candidate) <= k:
                            var exists = False
                            for j in range(len(updated)):
                                if updated[j] == candidate: exists = True
                            if not exists: updated.append(candidate)
                merged = updated^
        cuts[45 * v] = 1 << (3 * v)
        counts[v] = 1
        if degree > 0:
            for candidate in merged:
                var exists = False
                for j in range(counts[v]):
                    if cuts[45 * v + j] == candidate: exists = True
                if not exists:
                    cuts[45 * v + counts[v]] = candidate
                    counts[v] += 1
        for i in range(1, counts[v]):
            let candidate = cuts[45 * v + i]
            var j = i
            while j > 0 and cuts[45 * v + j - 1] > candidate:
                cuts[45 * v + j] = cuts[45 * v + j - 1]
                j -= 1
            cuts[45 * v + j] = candidate
    var words = List[Int64]()
    words.append(Int64(n))
    for v in range(n):
        words.append(Int64(counts[v]))
        for j in range(counts[v]): words.append(Int64(cuts[45 * v + j]))
    let bytes = 8 * len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(words)):
        for byte in range(8): output[8 * i + byte] = UInt8((words[i] >> (8 * byte)) & 255)
    return Int64(bytes)
