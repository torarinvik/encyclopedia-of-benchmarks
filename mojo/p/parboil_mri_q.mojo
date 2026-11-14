# Bounded direct MRI-Q magnitude and Fourier accumulation.
from std.collections import List
from std.ffi import c_size_t
from std.math import cos, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mri_decode(value: Int64) -> Float32:
    return Float32(value)/Float32(1000000.0)

fn mri_quantize(value: Float32) -> Int32:
    let scaled = value*Float32(1000.0)
    var magnitude = scaled
    if magnitude < 0.0: magnitude = -magnitude
    var whole = Int32(magnitude)
    if magnitude-Float32(whole) >= Float32(0.5): whole += 1
    if scaled < 0.0: return -whole
    return whole

@export("parboil_mri_q")
fn parboil_mri_q(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 24: return -1
    let nv = input[0]
    if nv < 1 or nv > 4 or length != c_size_t(4+5*nv): return -1
    let n = Int(nv)
    var values = List[Float32](capacity=Int(length)-1)
    for i in range(1,Int(length)):
        let raw = input[i]
        if raw < -1000000 or raw > 1000000: return -1
        values.append(mri_decode(raw))
    let x = values[0]
    let y = values[1]
    let z = values[2]
    var magnitudes = List[Float32](capacity=n)
    for i in range(n):
        let real = values[3+5*i+3]
        let imag = values[3+5*i+4]
        let real_square = real*real
        let imag_square = imag*imag
        magnitudes.append(real_square+imag_square)
    var qr = Float32(0.0)
    var qi = Float32(0.0)
    for i in range(n):
        let kx_x = values[3+5*i]*x
        let ky_y = values[3+5*i+1]*y
        let kz_z = values[3+5*i+2]*z
        let xy = kx_x+ky_y
        let xyz = xy+kz_z
        let phase = Float32(6.2831853071795864769)*xyz
        let real_term = magnitudes[i]*cos(phase)
        let imag_term = magnitudes[i]*sin(phase)
        qr += real_term
        qi += imag_term
    let real_bits = bitcast[UInt32](mri_quantize(qr))
    let imag_bits = bitcast[UInt32](mri_quantize(qi))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(4):
        output[byte] = UInt8((real_bits >> (8*byte)) & 255)
        output[4+byte] = UInt8((imag_bits >> (8*byte)) & 255)
    return 8
