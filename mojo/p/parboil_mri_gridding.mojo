# Clean-room Parboil MRI gridding profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mri_grid_decode(value: Int64) -> Float32:
    return Float32(value)/Float32(1000000.0)

fn mri_grid_quantize(value: Float32) -> Int64:
    let scaled = value*Float32(1000.0)
    var magnitude = scaled
    if magnitude < 0.0: magnitude = -magnitude
    var result = Int64(magnitude)
    if magnitude-Float32(result) >= Float32(0.5): result += 1
    if scaled < 0.0: return -result
    return result

fn mri_grid_kernel(value: Float32, coeff: List[Float32]) -> Float32:
    let z = value*value
    var numerator = coeff[0]
    for i in range(1,15): numerator = z*numerator+coeff[i]
    var denominator = z-Float32(0.307646912682801e4)
    denominator = z*denominator
    denominator += Float32(0.347626332405882e7)
    denominator = z*denominator
    denominator -= Float32(0.144048298227235e10)
    return -numerator/denominator

@export("parboil_mri_gridding")
fn parboil_mri_gridding(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 25: return -1
    let nv = input[0]
    if nv < 0 or nv > 4 or length != c_size_t(1+6*Int(nv)): return -1
    let n = Int(nv)
    var samples = List[Float32](capacity=6*n)
    for s in range(n):
        let base = 1+6*s
        for axis in range(3):
            let v = input[base+axis]
            if v != 0 and v != 1000000 and v != 2000000: return -1
        if input[base+3] < -1000000 or input[base+3] > 1000000 or input[base+4] < -1000000 or input[base+4] > 1000000 or input[base+5] < 0 or input[base+5] > 1000000: return -1
        for j in range(6): samples.append(mri_grid_decode(input[base+j]))
    var coeff = List[Float32](capacity=15)
    coeff.append(Float32(0.210580722890567e-22)); coeff.append(Float32(0.380715242345326e-19)); coeff.append(Float32(0.479440257548300e-16))
    coeff.append(Float32(0.435125971262668e-13)); coeff.append(Float32(0.300931127112960e-10)); coeff.append(Float32(0.160224679395361e-7))
    coeff.append(Float32(0.654858370096785e-5)); coeff.append(Float32(0.202591084143397e-2)); coeff.append(Float32(0.463076284721000e0))
    coeff.append(Float32(0.754337328948189e2)); coeff.append(Float32(0.830792541809429e4)); coeff.append(Float32(0.571661130563785e6))
    coeff.append(Float32(0.216415572361227e8)); coeff.append(Float32(0.356644482244025e9)); coeff.append(Float32(0.144048298227235e10))
    let width = Float32(2.5); let oversample = Float32(0.608933)
    var first = Float32(4.0)*width
    first *= width
    let divisor = oversample*oversample
    first /= divisor
    let shifted = Float64(oversample)-0.5
    var argument = Float64(first)*shifted
    argument *= shifted
    argument -= 0.8
    let beta = Float32(3.14159265359*sqrt(argument))
    let cutoff = Float32(Float64(width)/2.0)
    let cutoff2 = cutoff*cutoff
    let inverse = Float32(1.0)/cutoff2
    var real = List[Float32](length=27, fill=0.0)
    var imag = List[Float32](length=27, fill=0.0)
    var density = List[Float32](length=27, fill=0.0)
    for s in range(n):
        let p = 6*s
        let kx = samples[p]; let ky = samples[p+1]; let kz = samples[p+2]
        let sr = samples[p+3]; let si = samples[p+4]; let sdc = samples[p+5]
        if (sr == 0.0 and si == 0.0) or sdc == 0.0: continue
        var x0 = 0; var y0 = 0; var z0 = 0
        var x1 = 2; var y1 = 2; var z1 = 2
        if kx-cutoff >= 0.0: x0 = Int(kx-cutoff)
        if ky-cutoff >= 0.0: y0 = Int(ky-cutoff)
        if kz-cutoff >= 0.0: z0 = Int(kz-cutoff)
        if kx+cutoff <= 2.0: x1 = Int(kx+cutoff)
        if ky+cutoff <= 2.0: y1 = Int(ky+cutoff)
        if kz+cutoff <= 2.0: z1 = Int(kz+cutoff)
        for z in range(z0,z1+1):
            let dz = kz-Float32(z); let dz2 = dz*dz
            if dz2 >= cutoff2: continue
            for y in range(y0,y1+1):
                let dy = ky-Float32(y); let dy2 = dy*dy; let yz = dz2+dy2
                if yz >= cutoff2: continue
                for x in range(x0,x1+1):
                    let dx = kx-Float32(x); let dx2 = dx*dx; let distance = yz+dx2
                    if distance >= cutoff2: continue
                    let product = distance*inverse
                    let radicand = 1.0-Float64(product)
                    let weight_arg = Float32(Float64(beta)*sqrt(radicand))
                    let weight = mri_grid_kernel(weight_arg,coeff)*sdc
                    let idx = x+3*y+9*z
                    let dr = weight*sr; let di = weight*si
                    real[idx] += dr; imag[idx] += di
                    density[idx] = Float32(Float64(density[idx])+1.0)
    var checksum = Int64(0)
    for i in range(27): checksum += Int64(i+1)*(mri_grid_quantize(real[i])+mri_grid_quantize(imag[i])+Int64(density[i]))
    return checksum
