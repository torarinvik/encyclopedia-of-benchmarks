# Serial look-compute-move trace for exact ring covering.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("ring_exact_covering_protocol")
fn ring_exact_covering_protocol(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 79: return -1
    let nv = input[0]
    let visibility = input[1]
    let sv = input[2]
    if nv < 2 or nv > 12 or sv < 0 or sv > 64 or length != c_size_t(3+nv+sv): return -1
    let n = Int(nv)
    let steps = Int(sv)
    let circumference = 16*nv
    if visibility < 32 or visibility > circumference: return -1
    var positions = List[Int64](capacity=n)
    var schedule = List[Int](capacity=steps)
    for i in range(n):
        let position = input[3+i]
        if position < 0 or position >= circumference or (i > 0 and positions[i-1] >= position): return -1
        positions.append(position)
    for j in range(steps):
        let id = input[3+n+j]
        if id < 0 or id >= nv: return -1
        schedule.append(Int(id))
    var moved = Int64(0)
    for j in range(steps):
        let id = schedule[j]
        let next = (id+1)%n
        let gap = (positions[next]-positions[id]+circumference)%circumference
        var distance = Int64(0)
        if gap > visibility: distance = 16
        elif gap > 16: distance = gap-16
        if distance != 0:
            positions[id] = (positions[id]+distance)%circumference
            moved += 1
    var fields = List[Int64](capacity=2+2*n)
    fields.append(nv); fields.append(moved)
    for i in range(n): fields.append(positions[i])
    for i in range(n): fields.append((positions[(i+1)%n]-positions[i]+circumference)%circumference)
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
