# Bounded two-kernel Rodinia SRAD v2 recurrence.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_srad_v2")
fn rodinia_srad_v2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 258: return -1
    for i in range(258):
        if input[i] < 0 or input[i] > 4294967295: return -1
    if input[0] < 0x3c23d70a or input[0] > 0x3dcccccd or input[1] < 0x3c23d70a or input[1] > 0x3f800000: return -1
    let lambda = bitcast[Float32](UInt32(input[0]))
    let q0 = bitcast[Float32](UInt32(input[1]))
    var image = List[Float32](capacity=256)
    var coeff = List[Float32](capacity=256)
    var north = List[Float32](capacity=256)
    var south = List[Float32](capacity=256)
    var west = List[Float32](capacity=256)
    var east = List[Float32](capacity=256)
    for i in range(256):
        let bits = input[i+2]
        if bits < 0x3f800000 or bits > 0x3fa00000: return -1
        image.append(bitcast[Float32](UInt32(bits)))
        coeff.append(0.0); north.append(0.0); south.append(0.0); west.append(0.0); east.append(0.0)
    for row in range(16):
        for col in range(16):
            let i = row*16+col
            let center = image[i]
            var nr = row
            var sr = row
            var wc = col
            var ec = col
            if row > 0: nr -= 1
            if row < 15: sr += 1
            if col > 0: wc -= 1
            if col < 15: ec += 1
            let n = image[nr*16+col]-center
            let s = image[sr*16+col]-center
            let w = image[row*16+wc]-center
            let e = image[row*16+ec]-center
            north[i] = n; south[i] = s; west[i] = w; east[i] = e
            var gradient = n*n+s*s
            gradient += w*w
            gradient += e*e
            gradient /= center*center
            var laplacian = n+s
            laplacian += w
            laplacian += e
            laplacian /= center
            let lap_square = laplacian*laplacian
            let numerator = Float32(0.5*Float64(gradient)-(1.0/16.0)*Float64(lap_square))
            var denominator = Float32(1.0+0.25*Float64(laplacian))
            if denominator == 0.0: return -1
            let qsqr = numerator/(denominator*denominator)
            denominator = (qsqr-q0)/(q0*(Float32(1.0)+q0))
            if denominator == -1.0: return -1
            var value = Float32(1.0/(1.0+Float64(denominator)))
            if not isfinite(value): return -1
            if value < 0.0: value = 0.0
            if value > 1.0: value = 1.0
            coeff[i] = value
    var checksum = Int64(0)
    for row in range(16):
        for col in range(16):
            let i = row*16+col
            var sr = row
            var ec = col
            if row < 15: sr += 1
            if col < 15: ec += 1
            var divergence = coeff[i]*north[i]+coeff[sr*16+col]*south[i]
            divergence += coeff[i]*west[i]
            divergence += coeff[row*16+ec]*east[i]
            let updated = Float32(Float64(image[i])+0.25*Float64(lambda)*Float64(divergence))
            if not isfinite(updated) or updated < 0.0: return -1
            checksum += Int64(Float64(updated)*1000000.0+0.5)
    return checksum
