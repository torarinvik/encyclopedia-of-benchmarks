# One supplied-noise Rodinia naive particle-filter transition.
from std.collections import List
from std.ffi import c_size_t
from std.math import exp, floor, isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

fn particle_round(value: Float64) -> Int64:
    let scaled = value*1000.0
    if scaled < 0.0: return -Int64(floor(-scaled+0.5))
    return Int64(floor(scaled+0.5))

@export("rodinia_particlefilter_naive")
fn rodinia_particlefilter_naive(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 35: return -1
    let nv = input[0]
    let sv = input[1]
    let offset = input[2]
    if nv < 1 or nv > 4 or sv < 1 or sv > 4 or length != c_size_t(3+nv*(4+sv)) or offset < 0 or offset >= 1000000 or offset*nv >= 1000000: return -1
    let n = Int(nv)
    let samples = Int(sv)
    var xs = List[Float64](capacity=n)
    var ys = List[Float64](capacity=n)
    var weights = List[Float64](capacity=n)
    var cdf = List[Float64](capacity=n)
    for i in range(n):
        let base = 3+i*(4+samples)
        let x = input[base]; let y = input[base+1]
        let nx = input[base+2]; let ny = input[base+3]
        if x < -100000000 or x > 100000000 or y < -100000000 or y > 100000000 or nx < -2000000 or nx > 2000000 or ny < -2000000 or ny > 2000000: return -1
        xs.append(Float64(x)/1000000.0+1.0+5.0*(Float64(nx)/1000000.0))
        ys.append(Float64(y)/1000000.0-2.0+2.0*(Float64(ny)/1000000.0))
        var likelihood = Float64(0.0)
        for j in range(samples):
            let raw = input[base+4+j]
            if raw < 0 or raw > 255: return -1
            let foreground = Float64(raw-100)
            let background = Float64(raw-228)
            likelihood += (foreground*foreground-background*background)/50.0
        weights.append((1.0/Float64(n))*exp(likelihood/Float64(samples)))
        cdf.append(0.0)
    var sum = Float64(0.0)
    for i in range(n): sum += weights[i]
    if not isfinite(sum) or sum <= 0.0: return -1
    var estimate_x = Float64(0.0)
    var estimate_y = Float64(0.0)
    for i in range(n):
        weights[i] /= sum
        estimate_x += xs[i]*weights[i]
        estimate_y += ys[i]*weights[i]
        if i == 0: cdf[i] = weights[i]
        else: cdf[i] = weights[i]+cdf[i-1]
    var checksum = particle_round(estimate_x)+2*particle_round(estimate_y)
    for i in range(n):
        let u = Float64(offset)/1000000.0+Float64(i)/Float64(n)
        var selected = n-1
        for j in range(n):
            if cdf[j] >= u:
                selected = j
                break
        checksum += Int64(2*i+3)*particle_round(xs[selected])+Int64(2*i+4)*particle_round(ys[selected])
    return checksum
