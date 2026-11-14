# Independent bounded NBench kernel; see package LICENSE for upstream notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("nbench_neural_network")
fn nbench_neural_network(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let passes = input[0]
    if passes < 1 or passes > 8: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 88: return -2
    var pattern = List[Float64](length=35, fill=0.0)
    for i in range(35):
        let row = i//5; let col = i%5
        if (row == 0 or row == 6) and col >= 1 and col <= 3: pattern[i] = 1.0
        elif row >= 1 and row <= 4 and (col == 0 or col == 4): pattern[i] = 1.0
        elif row == 5 and col == 0: pattern[i] = 1.0
    var target = List[Float64](length=8, fill=0.0)
    target[1] = 1.0; target[4] = 1.0; target[5] = 1.0; target[6] = 1.0; target[7] = 1.0
    var mw = List[Float64](length=280, fill=0.0)
    var ow = List[Float64](length=64, fill=0.0)
    var mc = List[Float64](length=280, fill=0.0)
    var oc = List[Float64](length=64, fill=0.0)
    var mm = List[Float64](length=280, fill=0.0)
    var om = List[Float64](length=64, fill=0.0)
    var middle = List[Float64](length=8, fill=0.0)
    var result = List[Float64](length=8, fill=0.0)
    var oe = List[Float64](length=8, fill=0.0)
    var me = List[Float64](length=8, fill=0.0)
    for n in range(8):
        for w in range(35): mw[35*n+w] = Float64((17*n+7*w)%101-50)/1000.0
        for w in range(8): ow[8*n+w] = Float64((13*n+5*w)%71-35)/1000.0
    for _ in range(Int(passes)):
        for i in range(280): mc[i] = mm[i]; mm[i] = 0.0
        for i in range(64): oc[i] = om[i]; om[i] = 0.0
        for _ in range(2):
            for n in range(8):
                var sum = Float64(0.0)
                for w in range(35): sum += mw[35*n+w]*pattern[w]
                middle[n] = 1.0/(1.0+exp(-sum))
        for n in range(8):
            var sum = Float64(0.0)
            for w in range(8): sum += ow[8*n+w]*middle[w]
            result[n] = 1.0/(1.0+exp(-sum))
            oe[n] = target[n]-result[n]
        for n in range(8):
            var sum = Float64(0.0)
            for i in range(8): sum += ow[8*i+n]*oe[i]
            me[n] = middle[n]*(1.0-middle[n])*sum
        for n in range(8):
            for w in range(8):
                let idx = 8*n+w
                var delta = 0.09*oe[n]*middle[w]
                delta += 0.09*oc[idx]
                ow[idx] += delta; om[idx] += delta
        for n in range(8):
            for w in range(35):
                let idx = 35*n+w
                var delta = 0.09*me[n]*pattern[w]
                delta += 0.09*mc[idx]
                mw[idx] += delta; mm[idx] += delta
    var fields = List[Int64](length=11, fill=0)
    fields[0] = passes
    for n in range(8): fields[n+1] = Int64(result[n]*1000000.0)
    var middle_sum = Float64(0.0)
    var output_sum = Float64(0.0)
    for value in mw: middle_sum += value
    for value in ow: output_sum += value
    fields[9] = Int64(middle_sum*1000000.0); fields[10] = Int64(output_sum*1000000.0)
    for i in range(11):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return 88
