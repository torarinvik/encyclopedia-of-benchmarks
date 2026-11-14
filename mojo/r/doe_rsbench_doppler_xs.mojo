# Copyright (c) 2013 Argonne National Laboratory
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# Independent bounded RSBench Doppler lookup; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt, sin, cos, atan, exp, isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

@fieldwise_init
struct RsComplex(Copyable):
    var re: Float64
    var im: Float64

fn rs_add(a: RsComplex, b: RsComplex) -> RsComplex:
    return RsComplex(a.re+b.re,a.im+b.im)
fn rs_sub(a: RsComplex, b: RsComplex) -> RsComplex:
    return RsComplex(a.re-b.re,a.im-b.im)
fn rs_scale(a: RsComplex, b: Float64) -> RsComplex:
    return RsComplex(a.re*b,a.im*b)
fn rs_mul(a: RsComplex, b: RsComplex) -> RsComplex:
    return RsComplex(a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re)
fn rs_div(a: RsComplex, b: RsComplex) -> RsComplex:
    let norm=b.re*b.re+b.im*b.im
    return RsComplex((a.re*b.re+a.im*b.im)/norm,(a.im*b.re-a.re*b.im)/norm)

fn rs_w(z: RsComplex) -> RsComplex:
    let one=RsComplex(1.0,0.0); let imaginary=RsComplex(0.0,1.0)
    if sqrt(z.re*z.re+z.im*z.im)<6.0:
        let amplitude=exp(-12.0*z.im); let theta=12.0*z.re
        let e=RsComplex(amplitude*cos(theta),amplitude*sin(theta))
        let first=rs_div(rs_mul(imaginary,rs_sub(one,e)),rs_scale(z,12.0))
        let weights=InlineArray[Float64,10](0.2758402,0.2245740,0.1594149,0.09866577,0.05324414,0.02505215,0.01027747,0.003676164,0.001146494,0.0003117570)
        let den=InlineArray[Float64,10](9.869604,39.47842,88.82644,157.9137,246.7401,355.3058,483.6106,631.6547,799.4380,986.9604)
        var total=RsComplex(0.0,0.0)
        for i in range(10):
            let sign = -1.0 if i%2==0 else 1.0
            let numerator=rs_sub(rs_scale(e,sign),one)
            let denominator=rs_sub(RsComplex(den[i],0.0),rs_mul(rs_scale(z,144.0),z))
            total=rs_add(total,rs_scale(rs_div(numerator,denominator),weights[i]))
        return rs_add(first,rs_mul(rs_mul(RsComplex(0.0,81.24330),z),total))
    let square=rs_mul(z,z)
    let left=rs_div(RsComplex(0.512424224754768462984202823134979415014943561548661637413182,0.0),rs_sub(square,RsComplex(0.275255128608410950901357962647054304017026259671664935783653,0.0)))
    let right=rs_div(RsComplex(0.051765358792987823963876628425793170829107067780337219430904,0.0),rs_sub(square,RsComplex(2.724744871391589049098642037352945695982973740328335064216346,0.0)))
    return rs_mul(rs_mul(imaginary,z),rs_add(left,right))

@export("doe_rsbench_doppler_xs")
fn doe_rsbench_doppler_xs(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid=Float64(-1.0e300)
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<10 or length>100: return invalid
    let wv=input[0]; let pv=input[1]; let lv=input[2]; let ev=input[3]
    if wv<1 or wv>4 or pv<0 or pv>8 or lv<1 or lv>4 or ev<0 or ev>1000000: return invalid
    let nw=Int(wv); let np=Int(pv); let nl=Int(lv)
    let factor_base=4+5*nw; let pole_base=factor_base+nl
    if length!=c_size_t(pole_base+9*np): return invalid
    var backgrounds=InlineArray[Float64,12](fill=0)
    var starts=InlineArray[Int,4](fill=0); var ends=InlineArray[Int,4](fill=0)
    for i in range(nw):
        let at=4+5*i
        for j in range(3):
            if input[at+j]<0 or input[at+j]>1000000: return invalid
            backgrounds[3*i+j]=Float64(input[at+j])/1000000.0
        if input[at+3]<0 or input[at+3]>pv or input[at+4]<input[at+3] or input[at+4]>pv: return invalid
        starts[i]=Int(input[at+3]); ends[i]=Int(input[at+4])
    var pseudo=InlineArray[Float64,4](fill=0)
    for i in range(nl):
        let value=input[factor_base+i]
        if value<0 or value>1000000: return invalid
        pseudo[i]=Float64(value)/1000000.0
    for i in range(np):
        let at=pole_base+9*i
        for j in range(8):
            if input[at+j]<0 or input[at+j]>152500000: return invalid
        if input[at+8]<0 or input[at+8]>=lv: return invalid
    let energy=Float64(ev)/1000000.0
    var window=Int(energy/(1.0/Float64(nw)))
    if window==nw: window-=1
    if window>=nw: return invalid
    let root=sqrt(energy)
    var factors=InlineArray[RsComplex,4](fill=RsComplex(0.0,0.0))
    for i in range(nl):
        var phi=pseudo[i]*root
        if i==1: phi -= -atan(phi)
        elif i==2: phi-=atan(3.0*phi/(3.0-phi*phi))
        elif i==3: phi-=atan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi))
        phi*=2.0
        factors[i]=RsComplex(cos(phi),-sin(phi))
    var total=energy*backgrounds[3*window]
    var absorption=energy*backgrounds[3*window+1]
    var fission=energy*backgrounds[3*window+2]
    for i in range(starts[window],ends[window]):
        let at=pole_base+9*i
        let ea=RsComplex(Float64(input[at])/1000000.0,Float64(input[at+1])/1000000.0)
        let rt=RsComplex(Float64(input[at+2])/1000000.0,Float64(input[at+3])/1000000.0)
        let ra=RsComplex(Float64(input[at+4])/1000000.0,Float64(input[at+5])/1000000.0)
        let rf=RsComplex(Float64(input[at+6])/1000000.0,Float64(input[at+7])/1000000.0)
        let z=rs_scale(rs_sub(RsComplex(energy,0.0),ea),0.5)
        if z.re==0.0 and z.im==0.0: return invalid
        let w=rs_w(z)
        total+=rs_mul(rs_mul(rt,w),factors[Int(input[at+8])]).re
        absorption+=rs_mul(ra,w).re
        fission+=rs_mul(rf,w).re
    let elastic=total-absorption
    let answer=total+2.0*absorption+3.0*fission+5.0*elastic
    return answer if isfinite(answer) else invalid
