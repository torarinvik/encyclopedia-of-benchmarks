# Copyright (c) 2014 John Tramm. MIT license: see the package LICENSE file.
# Independently authored bounded SimpleMOC attenuation profile.
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, UnsafePointer

fn moc_fixed(value: Int64) -> Float32:
    return Float32(value) / Float32(1000000.0)

fn moc_exp(tau: Float32) -> Float32:
    let spacing = Float32(10.0) / Float32(353.0)
    if tau > Float32(10.0) - spacing: return Float32(1.0)
    let index = Int(tau / spacing + Float32(0.5) * spacing)
    let anchor = Float32(index) * spacing
    let exponential = Float32(exp(-Float64(anchor)))
    let slope = -exponential
    let intercept = Float32(1.0) + (anchor - Float32(1.0)) * exponential
    return slope * tau + intercept

@export("doe_simplemoc_quadratic_attenuation")
fn doe_simplemoc_quadratic_attenuation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 13 or length > 31: return -1.0e300
    let raw_groups = input[0]
    if raw_groups < 1 or raw_groups > 4: return -1.0e300
    let groups = Int(raw_groups)
    if Int(length) != 7 + 6 * groups: return -1.0e300
    for i in range(1, Int(length)):
        if input[i] < -10000000 or input[i] > 10000000: return -1.0e300
    if input[2] < 10000 or input[3] < 1000: return -1.0e300
    for i in range(4, 7):
        if input[i] < 0 or input[i] > 1000000: return -1.0e300
    let zin = moc_fixed(input[1])
    let dz = moc_fixed(input[2])
    let ds = moc_fixed(input[3])
    let mu = moc_fixed(input[4])
    let weight = moc_fixed(input[6]) * moc_fixed(input[5])
    let twice_zin = Float32(2.0) * zin
    if twice_zin > dz or -twice_zin > dz: return -1.0e300
    var checksum = Float32(0.0)
    for group in range(groups):
        let base = 7 + 6 * group
        if input[base + 3] < 100000 or input[base + 4] < 0 or input[base + 5] < 0: return -1.0e300
        let previous = moc_fixed(input[base])
        let center = moc_fixed(input[base + 1])
        let following = moc_fixed(input[base + 2])
        let sigma = moc_fixed(input[base + 3])
        let psi = moc_fixed(input[base + 4])
        let tally = moc_fixed(input[base + 5])
        let twice_dz = Float32(2.0) * dz
        let c1 = (previous - following) / twice_dz
        let c2 = ((previous - Float32(2.0) * center) + following) / (twice_dz * dz)
        let q0 = (center + c1 * zin) + (c2 * zin) * zin
        let q1 = c1 + (Float32(2.0) * c2) * zin
        let tau = sigma * ds
        if tau <= Float32(0.0) or tau > Float32(10.0): return -1.0e300
        let attenuation = moc_exp(tau)
        let sigma2 = sigma * sigma
        let reuse = tau * (tau - Float32(2.0)) + (Float32(2.0) * attenuation) / (sigma * sigma2)
        let part1 = (q0 * tau + (sigma * psi - q0) * attenuation) / sigma2
        let part2 = (q1 * mu) * reuse
        let mu2 = mu * mu
        let polynomial = tau * (tau * (tau - Float32(3.0)) + Float32(6.0)) - Float32(6.0) * attenuation
        let part3 = ((c2 * mu2) * polynomial) / ((Float32(3.0) * sigma2) * sigma2)
        let tally_out = tally + weight * ((part1 + part2) + part3)
        let term1 = (q0 * attenuation) / sigma
        let term2 = ((q1 * mu) * (tau - attenuation)) / sigma2
        let term3 = (c2 * mu2) * reuse
        let term4 = psi * (Float32(1.0) - attenuation)
        let psi_out = ((term1 + term2) + term3) + term4
        checksum += Float32(group + 1) * (tally_out + psi_out)
    return Float64(checksum)
