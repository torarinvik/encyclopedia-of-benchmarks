from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn adam_sqrt(value: Float64) -> Float64:
    if value <= 0.0:
        return 0.0
    var root = value
    if root < 1.0:
        root = 1.0
    for _ in range(80):
        root = 0.5 * (root + value / root)
    return root

fn adam_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[pos + b] = UInt8((bits >> (8 * b)) & 255)

@export("adam")
fn adam(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 4103:
        return -1
    let steps = input[0]
    let pcount = input[1]
    let lrv = input[2]
    let b1v = input[3]
    let b2v = input[4]
    let epsv = input[5]
    let wdv = input[6]
    if steps < 1 or steps > 256 or pcount < 1 or pcount > 16:
        return -1
    if length != c_size_t(7 + pcount + steps * pcount) or lrv < 1 or lrv > 1000000000 or b1v < 0 or b1v >= 1000000000 or b2v < 0 or b2v >= 1000000000 or epsv < 1 or epsv > 10000000 or wdv < 0 or wdv > 100000000:
        return -1
    for i in range(pcount):
        if input[7 + i] < -1000000000000000 or input[7 + i] > 1000000000000000:
            return -1
    let grad_start = 7 + pcount
    for i in range(steps * pcount):
        if input[grad_start + i] < -1000000000000 or input[grad_start + i] > 1000000000000:
            return -1
    let outputs = steps * pcount
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * outputs):
        return -2
    let lr = Float64(lrv) / 1000000000.0
    let beta1 = Float64(b1v) / 1000000000.0
    let beta2 = Float64(b2v) / 1000000000.0
    let epsilon = Float64(epsv) / 1000000000.0
    let decay = Float64(wdv) / 1000000000.0
    var parameters = List[Float64](length=Int(pcount), fill=0.0)
    var first = List[Float64](length=Int(pcount), fill=0.0)
    var second = List[Float64](length=Int(pcount), fill=0.0)
    for i in range(pcount):
        parameters[i] = Float64(input[7 + i]) / 1000000000.0
    var b1power: Float64 = 1.0
    var b2power: Float64 = 1.0
    for step in range(steps):
        b1power *= beta1
        b2power *= beta2
        for i in range(pcount):
            let g = Float64(input[grad_start + step * pcount + i]) / 1000000000.0
            first[i] = beta1 * first[i] + (1.0 - beta1) * g
            second[i] = beta2 * second[i] + (1.0 - beta2) * (g * g)
            let mh = first[i] / (1.0 - b1power)
            let vh = second[i] / (1.0 - b2power)
            let updated = parameters[i] - lr * mh / (adam_sqrt(vh) + epsilon) - lr * decay * parameters[i]
            parameters[i] = updated
            adam_write_i64(output, Int(8 * (step * pcount + i)), Int64(updated * 1000000.0))
    return outputs
