from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import cos, sin

fn ifft_transform(mut real:InlineArray[Float64,64],mut imag:InlineArray[Float64,64],n:Int):
    var reverse=0
    for position in range(1,n):
        var bit=n//2
        while (reverse&bit)!=0:reverse^=bit;bit>>=1
        reverse^=bit
        if position<reverse:
            let t=real[position];real[position]=real[reverse];real[reverse]=t
            let u=imag[position];imag[position]=imag[reverse];imag[reverse]=u
    var block=2
    while block<=n:
        let angle=6.283185307179586476925286766559/Float64(block)
        let sr=cos(angle);let si= -sin(angle)
        for start in range(0,n,block):
            var wr=1.0;var wi=0.0
            for offset in range(block//2):
                let first=start+offset;let second=first+block//2
                let pr=wr*real[second]-wi*imag[second];let pi=wr*imag[second]+wi*real[second]
                let fr=real[first];let fi=imag[first]
                real[first]=fr+pr;imag[first]=fi+pi;real[second]=fr-pr;imag[second]=fi-pi
                let nr=wr*sr-wi*si;wi=wr*si+wi*sr;wr=nr
        block*=2
fn ifft_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("inverse_fast_fourier_transform")
fn inverse_fast_fourier_transform(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                                  output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>129:return -1
    let nv=input[0]
    if nv<1 or nv>64 or (nv&(nv-1))!=0 or length!=c_size_t(1+2*nv):return -1
    let n=Int(nv)
    for i in range(2*n):
        if input[i+1]< -1000 or input[i+1]>1000:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n*8):return -2
    var real=InlineArray[Float64,64](fill=0.0);var imag=InlineArray[Float64,64](fill=0.0)
    for i in range(n):real[i]=Float64(input[1+2*i]);imag[i]=Float64(input[2+2*i])
    ifft_transform(mut real,mut imag,n)
    for i in range(n):
        let x=real[i]/Float64(n);let scaled=x*1000000.0
        let q=Int64(scaled+0.5 if scaled>=0.0 else scaled-0.5)
        ifft_store(output,i*8,q)
    return Int64(n*8)
