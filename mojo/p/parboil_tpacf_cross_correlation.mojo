# Clean-room Parboil TPACF profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.math import cos, log10, pow
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("parboil_tpacf_cross_correlation")
fn parboil_tpacf_cross_correlation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 26: return -1
    let dv = input[0]; let rv = input[1]
    if dv < 1 or dv > 4 or rv < 1 or rv > 4: return -1
    let data_count = Int(dv); let random_count = Int(rv)
    if length != c_size_t(2+3*(data_count+random_count)): return -1
    var points = List[Float32](capacity=3*(data_count+random_count))
    for i in range(2,Int(length)):
        let value = input[i]
        if value < -1000000 or value > 1000000: return -1
        points.append(Float32(value)/Float32(1000000.0))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 20: return -2
    var boundaries = List[Float32](capacity=21)
    for k in range(21):
        let exponent = log10(Float64(1.0))+Float64(k)*1.0/5.0
        let arcminutes = pow(Float64(10.0),exponent)
        let radians = arcminutes/60.0*(Float64(3.141592653589793238462643383279502884)/180.0)
        boundaries.append(Float32(cos(radians)))
    var histogram = List[UInt8](length=20, fill=0)
    for j in range(random_count):
        let base = 3*(data_count+j)
        for i in range(data_count):
            let px = points[3*i]*points[base]
            let py = points[3*i+1]*points[base+1]
            let pz = points[3*i+2]*points[base+2]
            let xy = px+py
            let distance = xy+pz
            var lower = 0
            var upper = 20
            while upper > lower+1:
                let middle = (lower+upper)//2
                if distance >= boundaries[middle]: upper = middle
                else: lower = middle
            if distance < boundaries[lower] and distance >= boundaries[upper]: histogram[upper-1] += 1
    for i in range(20): output[i] = histogram[i]
    return 20
