from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("assembly_line_scheduling")
fn assembly_line_scheduling(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or values[0] < 1 or values[0] > 64:
        return -1
    let n = Int(values[0])
    if length != c_size_t(4 * n + 3):
        return -1
    for i in range(Int(length)):
        if values[i] < 0 or values[i] > 1000:
            return -1
    let a0 = 1
    let a1 = a0 + n
    let t0 = a1 + n
    let t1 = t0 + n - 1
    let entry = t1 + n - 1
    var line0 = values[entry] + values[a0]
    var line1 = values[entry + 1] + values[a1]
    for station in range(1, n):
        let stay0 = line0 + values[a0 + station]
        let switch0 = line1 + values[t1 + station - 1] + values[a0 + station]
        let stay1 = line1 + values[a1 + station]
        let switch1 = line0 + values[t0 + station - 1] + values[a1 + station]
        line0 = min(stay0, switch0)
        line1 = min(stay1, switch1)
    let answer = min(line0 + values[entry + 2], line1 + values[entry + 3])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 4:
        return -2
    let bits = UInt32(answer)
    for b in range(4):
        output[b] = UInt8((bits >> UInt(8 * b)) & 255)
    return 4
