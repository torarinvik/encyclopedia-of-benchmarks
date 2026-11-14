# Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin, sqrt, isfinite, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mafft_channel(code: Int) -> Int:
    let codes = InlineArray[Int,20](65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86)
    for i in range(20):
        if codes[i] == code: return i
    return -1

fn mafft_fft(mut re: InlineArray[Float64,64], mut im: InlineArray[Float64,64], n: Int, inverse: Bool):
    var j=0
    for i in range(1,n):
        var bit=n >> 1
        while (j & bit)!=0:
            j^=bit
            bit>>=1
        j^=bit
        if i<j:
            let tr=re[i]; re[i]=re[j]; re[j]=tr
            let ti=im[i]; im[i]=im[j]; im[j]=ti
    var span=2
    while span<=n:
        let angle=(1.0 if inverse else -1.0)*6.2831853071795864769/Float64(span)
        let cr=cos(angle); let ci=sin(angle)
        for start in range(0,n,span):
            var wr=Float64(1); var wi=Float64(0)
            for k in range(span//2):
                let a=start+k; let b=a+span//2
                let pr=wr*re[b]-wi*im[b]; let pi=wr*im[b]+wi*re[b]
                let ar=re[a]; let ai=im[a]
                re[a]=ar+pr; im[a]=ai+pi
                re[b]=ar-pr; im[b]=ai-pi
                let next_wr=wr*cr-wi*ci
                wi=wr*ci+wi*cr; wr=next_wr
        span*=2
    if not inverse:
        for i in range(n): re[i]/=Float64(n); im[i]/=Float64(n)

@export("mafft_falign_fft_lag_correlation")
fn mafft_falign_fft_lag_correlation(input: UnsafePointer[Float64,ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[Float64,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<4 or length>66: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]) or trunc(input[i])!=input[i]: return -1
    if input[0]<1 or input[0]>32 or input[1]<1 or input[1]>32: return -1
    let n1=Int(input[0]); let n2=Int(input[1])
    if length!=c_size_t(2+n1+n2): return -1
    for i in range(2,Int(length)):
        if input[i]<65 or input[i]>90 or mafft_channel(Int(input[i]))<0: return -1
    var n=1
    while n<=max(n1,n2): n*=2
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(n): return -2
    let polarity=InlineArray[Float64,20](8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9)
    let volume=InlineArray[Float64,20](31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0)
    var mean_p=Float64(0); var mean_v=Float64(0)
    for i in range(20): mean_p+=polarity[i]; mean_v+=volume[i]
    mean_p/=20; mean_v/=20
    var var_p=Float64(0); var var_v=Float64(0)
    for i in range(20):
        let dp=polarity[i]-mean_p; let dv=volume[i]-mean_v
        var_p+=dp*dp; var_v+=dv*dv
    let sd_p=sqrt(var_p/20); let sd_v=sqrt(var_v/20)
    var r1=InlineArray[Float64,64](fill=0); var i1=InlineArray[Float64,64](fill=0)
    var r2=InlineArray[Float64,64](fill=0); var i2=InlineArray[Float64,64](fill=0)
    for i in range(n1):
        let ch=mafft_channel(Int(input[2+i]))
        r1[i]=(polarity[ch]-mean_p)/sd_p; i1[i]=(volume[ch]-mean_v)/sd_v
    for i in range(n2):
        let ch=mafft_channel(Int(input[2+n1+i]))
        r2[i]=(polarity[ch]-mean_p)/sd_p; i2[i]=(volume[ch]-mean_v)/sd_v
    mafft_fft(r1,i1,n,False); mafft_fft(r2,i2,n,False)
    var re=InlineArray[Float64,64](fill=0); var im=InlineArray[Float64,64](fill=0)
    for i in range(n):
        re[i]=r1[i]*r2[i]+i1[i]*i2[i]
        im[i]=i1[i]*r2[i]-r1[i]*i2[i]
    mafft_fft(re,im,n,True)
    for i in range(n): output[i]=re[(n//2+n-i)%n]
    return Int64(n)
