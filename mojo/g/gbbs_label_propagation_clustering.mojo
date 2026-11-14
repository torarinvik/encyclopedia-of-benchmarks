# Independent bounded GBBS label-propagation profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_label_propagation_clustering")
fn gbbs_label_propagation_clustering(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var labels = List[Int](capacity=n)
    for u in range(n):
        rows.append(0)
        labels.append(u)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    for u in range(n):
        if rows[u] == 0: continue
        var frequency = List[Int](capacity=n)
        for _ in range(n): frequency.append(0)
        for v in range(n):
            if (rows[u] & (1 << v)) != 0: frequency[labels[v]] += 1
        var selected = 0
        var maximum = 0
        for label in range(n):
            if frequency[label] > maximum or (frequency[label] == maximum and maximum > 0 and label > selected):
                selected = label
                maximum = frequency[label]
        labels[u] = selected
    for u in range(n):
        let value = Int64(labels[u])
        for byte in range(8): output[8*u+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
