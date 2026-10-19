from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import cos, sin, sqrt, exp, log, log10, floor, isfinite

comptime MF_PI=3.14159265358979323846264338327950288
fn mf_fft(mut re:InlineArray[Float64,1024],mut im:InlineArray[Float64,1024],n:Int):
    var j=0
    for i in range(1,n):
        var bit=n>>1
        while (j&bit)!=0:j^=bit;bit>>=1
        j^=bit
        if i<j:
            let t=re[i];re[i]=re[j];re[j]=t;let q=im[i];im[i]=im[j];im[j]=q
    var len=2
    while len<=n:
        let angle=-2.0*MF_PI/Float64(len);let sr=cos(angle);let si=sin(angle);let half=len>>1
        for start in range(0,n,len):
            var wr=1.0;var wi=0.0
            for k in range(half):
                let even=start+k;let odd=even+half;let tr=wr*re[odd]-wi*im[odd];let ti=wr*im[odd]+wi*re[odd]
                re[odd]=re[even]-tr;im[odd]=im[even]-ti;re[even]+=tr;im[even]+=ti
                let nw=wr*sr-wi*si;wi=wr*si+wi*sr;wr=nw
        len<<=1
fn mf_round_even(x:Float64)->Int:
    let lo=Int(floor(x));let frac=x-Float64(lo)
    if frac<0.5:return lo
    if frac>0.5:return lo+1
    return lo if lo%2==0 else lo+1
fn mf_put(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for i in range(8):out[p+i]=UInt8((bits>>(8*i))&255)
@export("mfcc")
fn mfcc(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>2054:return -1
    let ns=v[0];let sr0=v[1];let hopms=v[2];let fft0=v[3];let mel0=v[4];let dct0=v[5]
    if ns<33 or ns>2048 or Int(n)!=Int(ns)+6 or sr0<8000 or sr0>48000 or hopms<1 or hopms>50:return -1
    if fft0!=64 and fft0!=128 and fft0!=256 and fft0!=512 and fft0!=1024:return -1
    if mel0<2 or mel0>16 or dct0<1 or dct0>40:return -1
    let count=Int(ns);let sr=Int(sr0);let fn=Int(fft0);let mels=Int(mel0);let dcts=Int(dct0)
    if count<fn//2+1:return -1
    let hop=mf_round_even(Float64(sr*Int(hopms))/1000.0)
    if hop<=0:return -1
    var audio=InlineArray[Float64,2048](fill=0.0);var peak=0.0
    for i in range(count):
        let sample=bitcast[Float64](UInt64(v[6+i]))
        if not isfinite(sample) or sample < -1000000.0 or sample>1000000.0:return -1
        audio[i]=sample
        if sample<0.0:
            if -sample>peak:peak=-sample
        elif sample>peak:peak=sample
    if peak==0.0:return -1
    for i in range(count):audio[i]/=peak
    let pad=fn//2;let frames=count//hop+1;let binsn=fn//2+1
    if frames>257:return -1
    var padded=InlineArray[Float64,3072](fill=0.0)
    for i in range(pad):padded[i]=audio[pad-i]
    for i in range(count):padded[pad+i]=audio[i]
    for i in range(pad):padded[pad+count+i]=audio[count-2-i]
    var freqs=InlineArray[Float64,18](fill=0.0);var bins=InlineArray[Int64,18](fill=0)
    let melhi=2595.0*log(1.0+Float64(sr//2)/700.0)/log(10.0)
    for i in range(mels+2):
        let mel=melhi*Float64(i)/Float64(mels+1);let hz=700.0*(exp(log(10.0)*mel/2595.0)-1.0)
        freqs[i]=hz;let bf=floor(Float64(fn+1)/Float64(sr)*hz)
        if bf<0.0 or bf>=Float64(binsn):return -1
        bins[i]=Int64(bf)
    for i in range(mels+1):if bins[i]>=bins[i+1]:return -1
    var norms=InlineArray[Float64,16](fill=0.0)
    for i in range(mels):norms[i]=2.0/(freqs[i+2]-freqs[i]);if not isfinite(norms[i]):return -1
    var logged=InlineArray[Float64,16*257](fill=0.0);var win=InlineArray[Float64,1024](fill=0.0)
    for i in range(fn):win[i]=0.5-0.5*cos(2.0*MF_PI*Float64(i)/Float64(fn))
    for frame in range(frames):
        var re=InlineArray[Float64,1024](fill=0.0);var im=InlineArray[Float64,1024](fill=0.0)
        for i in range(fn):re[i]=padded[frame*hop+i]*win[i]
        mf_fft(mut re,mut im,fn)
        var power=InlineArray[Float64,513](fill=0.0)
        for k in range(binsn):
            let rf=Float32(re[k]);let qf=Float32(im[k]);let p=(rf*rf+qf*qf);power[k]=Float64(p)
        for f in range(mels):
            let start=Int(bins[f]);let mid=Int(bins[f+1]);let end=Int(bins[f+2]);let rising=mid-start;let falling=end-mid;var energy=0.0
            for k in range(start,mid):
                let w=if rising==1:0.0 else:Float64(k-start)/Float64(rising-1)
                energy+=power[k]*w
            for k in range(mid,end):
                let w=if falling==1:1.0 else:1.0-Float64(k-mid)/Float64(falling-1)
                energy+=power[k]*w
            energy*=norms[f]
            if not isfinite(energy) or energy<=0.0:return -1
            logged[f*257+frame]=10.0*log10(energy)
    var result=InlineArray[Float64,10280](fill=0.0)
    for d in range(dcts):
        let scale=if d==0:1.0/sqrt(Float64(mels)) else:sqrt(2.0/Float64(mels))
        for frame in range(frames):
            var sum=0.0
            for j in range(mels):
                let basis=if d==0:scale else:scale*cos(Float64(d)*(2.0*Float64(j)+1.0)*MF_PI/(2.0*Float64(mels)))
                sum+=basis*logged[j*257+frame]
            if not isfinite(sum):return -1
            result[d*257+frame]=sum
    let bytes=dcts*frames*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var pos=0
    for d in range(dcts):
        for frame in range(frames):mf_put(out,pos,result[d*257+frame]);pos+=8
    return Int64(bytes)
