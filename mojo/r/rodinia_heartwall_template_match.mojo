# Bounded Heartwall normalized template score and first maximum.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("rodinia_heartwall_template_match")
fn rodinia_heartwall_template_match(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 85: return -1
    let irv = input[0]; let icv = input[1]; let trv = input[2]; let tcv = input[3]; let mask = input[4]
    if irv < 2 or irv > 8 or icv < 2 or icv > 8 or trv < 2 or trv > 4 or tcv < 2 or tcv > 4 or trv > irv or tcv > icv or mask < 0: return -1
    let ir = Int(irv); let ic = Int(icv); let tr = Int(trv); let tc = Int(tcv)
    let nr = ir-tr+1; let nc = ic-tc+1
    if (mask >> (nr*nc)) != 0 or length != c_size_t(5+tr*tc+ir*ic): return -1
    var template = List[Float32](capacity=tr*tc)
    var image = List[Float32](capacity=ir*ic)
    for i in range(tr*tc):
        let value = input[5+i]
        if value < 0 or value > 255: return -1
        template.append(Float32(value))
    for i in range(ir*ic):
        let value = input[5+tr*tc+i]
        if value < 0 or value > 255: return -1
        image.append(Float32(value))
    var sum = Float32(0.0)
    var square = Float32(0.0)
    for c in range(tc):
        for r in range(tr):
            let value = template[c*tr+r]
            sum += value
            square += value*value
    let count = Float32(tr*tc)
    let mean = sum/count
    let variance = square/count-mean*mean
    if variance <= 0.0: return -1
    var best = Float32(0.0)
    var best_index = 0
    var index = 0
    for c0 in range(nc):
        for r0 in range(nr):
            if (mask & (Int64(1) << index)) != 0:
                var patch_sum = Float32(0.0)
                var patch_square = Float32(0.0)
                var dot = Float32(0.0)
                for c in range(tc):
                    for r in range(tr):
                        let x = template[c*tr+r]
                        let y = image[(c0+c)*ir+r0+r]
                        patch_sum += y
                        patch_square += y*y
                        dot += x*y
                var centered = patch_square-patch_sum*patch_sum/count
                if centered < 0.0: centered = 0.0
                if centered <= 0.0: return -1
                let numerator = dot-patch_sum*sum/count
                let template_denominator = sqrt(Float32(tr*tc-1))*sqrt(variance)
                let score = numerator/(sqrt(centered)*template_denominator)
                if not isfinite(score): return -1
                var magnitude = score
                if magnitude < 0.0: magnitude = -magnitude
                if magnitude > best:
                    best = magnitude
                    best_index = index
            index += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((Int64(best_index) >> (8*byte)) & 255)
    return 8
