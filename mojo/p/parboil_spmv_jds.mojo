# Preconverted Parboil jagged-diagonal sparse matrix-vector product.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("parboil_spmv_jds")
fn parboil_spmv_jds(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 164: return -1
    let nv = input[0]
    let dv = input[1]
    let zv = input[2]
    if nv < 1 or nv > 8 or dv < 1 or dv > 8 or zv < 1 or zv > 64 or length != c_size_t(4+3*nv+dv+2*zv): return -1
    let n = Int(nv)
    let d = Int(dv)
    let z = Int(zv)
    var rows = List[Int](capacity=n)
    var permutation = List[Int](capacity=n)
    var offsets = List[Int](capacity=d+1)
    var columns = List[Int](capacity=z)
    var data = List[Float32](capacity=z)
    var vector = List[Float32](capacity=n)
    var result = List[Float32](capacity=n)
    var pos = 3
    for i in range(n):
        let value = input[pos]; pos += 1
        if value < 0 or value > dv or (i == 0 and value != dv): return -1
        if i > 0 and value > Int64(rows[i-1]): return -1
        rows.append(Int(value)); result.append(0.0)
    var seen = 0
    for _ in range(n):
        let value = input[pos]; pos += 1
        if value < 0 or value >= nv: return -1
        let person = Int(value)
        if (seen & (1 << person)) != 0: return -1
        seen |= 1 << person
        permutation.append(person)
    for _ in range(d+1):
        let value = input[pos]; pos += 1
        if value < 0 or value > zv: return -1
        offsets.append(Int(value))
    if offsets[0] != 0: return -1
    var count = 0
    for k in range(d):
        for i in range(n):
            if rows[i] > k: count += 1
        if offsets[k+1] != count: return -1
    if count != z: return -1
    for _ in range(z):
        let value = input[pos]; pos += 1
        if value < 0 or value >= nv: return -1
        columns.append(Int(value))
    for _ in range(z):
        let value = input[pos]; pos += 1
        if value < -1000000 or value > 1000000: return -1
        data.append(Float32(value)/Float32(1000000.0))
    for _ in range(n):
        let value = input[pos]; pos += 1
        if value < -1000000 or value > 1000000: return -1
        vector.append(Float32(value)/Float32(1000000.0))
    for rank in range(n):
        var sum = Float32(0.0)
        for k in range(rows[rank]):
            let index = offsets[k]+rank
            let product = data[index]*vector[columns[index]]
            sum += product
        result[permutation[rank]] = sum
    let bytes = 4+4*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(4): output[byte] = UInt8((UInt32(n) >> (8*byte)) & 255)
    for i in range(n):
        let bits = bitcast[UInt32](result[i])
        for byte in range(4): output[4+4*i+byte] = UInt8((bits >> (8*byte)) & 255)
    return Int64(bytes)
