from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_JOBS = 4
comptime MAX_SAMPLES = 8
comptime MAX_OUTPUT = 136
comptime E_NUM = 271828
comptime E_DEN = 100000
comptime EM1_NUM = 171828

fn bkp_gcd(a: Int64, b: Int64) -> Int64:
    var x = a
    var y = b
    while y != 0:
        let r = x % y
        x = y
        y = r
    if x < 0: return -x
    return x

fn bkp_put64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset+byte] = UInt8((bits >> (8*byte)) & 255)

@export("bkp_speed_scaling_trace")
fn bkp_speed_scaling_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(31): return -1
    let n64 = input[0]
    let samples64 = input[1]
    if n64 < 1 or n64 > MAX_JOBS or samples64 < 1 or samples64 > MAX_SAMPLES: return -1
    let n = Int(n64)
    let samples = Int(samples64)
    if Int64(length) != Int64(2+3*n+2*samples): return -1
    var release = InlineArray[Int64, MAX_JOBS](fill=0)
    var deadline = InlineArray[Int64, MAX_JOBS](fill=0)
    var work = InlineArray[Int64, MAX_JOBS](fill=0)
    for j in range(n):
        release[j] = input[2+3*j]
        deadline[j] = input[3+3*j]
        work[j] = input[4+3*j]
        if release[j] < 0 or release[j] >= deadline[j] or deadline[j] > 8 or work[j] < 1 or work[j] > 8: return -1
    var values = InlineArray[Int64, 17](fill=0)
    values[0] = samples64
    for sample in range(samples):
        let t = input[2+3*n+2*sample]
        let mask = input[3+3*n+2*sample]
        if t < 0 or t > 8 or mask < 0 or mask >= (Int64(1) << n): return -1
        for j in range(n):
            if (mask & (Int64(1) << j)) != 0 and release[j] > t: return -1
        var bestNum: Int64 = 0
        var bestDen: Int64 = 1
        if mask != 0:
            for source in range(n):
                if release[source] <= t:
                    if deadline[source] > t:
                        let xNum = deadline[source]
                        let xDen: Int64 = 1
                        let delta = xNum-t*xDen
                        let left = E_NUM*t*xDen-EM1_NUM*xNum
                        var total: Int64 = 0
                        for j in range(n):
                            if release[j] <= t and left <= E_DEN*xDen*release[j] and deadline[j]*xDen <= xNum: total += work[j]
                        let num = total*xDen
                        if delta > 0 and num*bestDen > bestNum*delta:
                            bestNum = num
                            bestDen = delta
                    if release[source] < t:
                        let xNum = E_NUM*t-E_DEN*release[source]
                        let xDen: Int64 = EM1_NUM
                        let delta = xNum-t*xDen
                        let left = E_NUM*t*xDen-EM1_NUM*xNum
                        var total: Int64 = 0
                        for j in range(n):
                            if release[j] <= t and left <= E_DEN*xDen*release[j] and deadline[j]*xDen <= xNum: total += work[j]
                        let num = total*xDen
                        if delta > 0 and num*bestDen > bestNum*delta:
                            bestNum = num
                            bestDen = delta
        let divisor = bkp_gcd(bestNum,bestDen)
        values[1+2*sample] = bestNum // divisor
        values[2+2*sample] = bestDen // divisor
    let outputBytes = 8*(1+2*samples)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(outputBytes): return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    for i in range(1+2*samples): bkp_put64(staged.unsafe_ptr(),8*i,values[i])
    for i in range(outputBytes): output[i] = staged[i]
    return Int64(outputBytes)
