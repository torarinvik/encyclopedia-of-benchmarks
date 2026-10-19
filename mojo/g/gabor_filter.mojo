from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import cos, exp, sin

fn gf_put_f32(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, x: Float64):
    let bits = bitcast[UInt32](Float32(x))
    for b in range(4): out[pos+b] = UInt8((bits >> UInt32(8*b)) & 255)

@export("gabor_filter")
fn gabor_filter(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 6: return -1
    let req=v[0]; let sigma=v[1]; let theta=v[2]; let wave=v[3]; let gamma=v[4]; let phase=v[5]
    if req<1 or req>7 or sigma<1 or sigma>8 or theta<0 or theta>359 or wave<1 or wave>8 or gamma<0 or gamma>4 or phase< -6 or phase>6:return -1
    var side=Int(req); if side%2==0:side+=1
    let bytes=side*side*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    let pi=3.14159265358979323846; let angle=Float64(theta)*pi/180.0; let co=cos(angle); let si=sin(angle); let center=side//2
    for y in range(side):
        for x in range(side):
            let px=Float64(x-center); let py=Float64(y-center)
            let kx=co*px+si*py; let ky= -si*px+co*py
            let exponent= -(kx*kx+Float64(gamma*gamma)*ky*ky)/(2.0*Float64(sigma)*Float64(sigma))
            let angle2=2.0*pi*kx/Float64(wave)+Float64(phase)
            gf_put_f32(out,(y*side+x)*4,exp(exponent)*cos(angle2))
    return Int64(bytes)
