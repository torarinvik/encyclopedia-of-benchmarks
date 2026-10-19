from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import exp, isfinite, log, sqrt

fn gmm_pdf(x:Float64,mu:Float64,var:Float64)->Float64:
    let d=x-mu;return exp(-(d*d)/(2.0*var))/sqrt(6.28318530717958647692*var)

@export("gaussian_mixture_model")
fn gaussian_mixture_model(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>19:return -1
    let count=Int(v[0]);let maxit=Int(v[1]);let tm=v[2]
    if count<2 or count>16 or maxit<1 or maxit>20 or tm<1 or tm>1000 or n!=c_size_t(3+count):return -1
    var data=InlineArray[Float64,16](fill=0.0);var previous:Int64= -9223372036854775807
    for i in range(count):
        let s=v[3+i];if s< -5000 or s>5000 or s<previous:return -1
        previous=s;data[i]=Float64(s)/1000.0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count+1):return -2
    var mean=0.0
    for i in range(count):mean+=data[i]
    mean/=Float64(count)
    var variance=0.0
    for i in range(count):let d=data[i]-mean;variance+=d*d
    variance=variance/Float64(count-1)+1.0e-6
    var weights=InlineArray[Float64,2](fill=0.5);var means=InlineArray[Float64,2](fill=0.0);means[0]=data[0];means[1]=data[count-1]
    var vars=InlineArray[Float64,2](fill=variance);var resp=InlineArray[Float64,32](fill=0.0)
    let tolerance=Float64(tm)/1000000.0;var prevll=0.0;var hasprev=False;var iterations=0
    for iteration in range(maxit):
        var counts=InlineArray[Float64,2](fill=0.0)
        for i in range(count):
            let p0=weights[0]*gmm_pdf(data[i],means[0],vars[0]);let p1=weights[1]*gmm_pdf(data[i],means[1],vars[1]);let total=p0+p1
            if total==0.0 or not isfinite(total):return -1
            resp[i]=p0/total;resp[16+i]=p1/total;counts[0]+=resp[i];counts[1]+=resp[16+i]
        if counts[0]<=0.0 or counts[1]<=0.0:return -1
        for comp in range(2):
            weights[comp]=counts[comp]/Float64(count);var weighted=0.0
            for i in range(count):weighted+=resp[comp*16+i]*data[i]
            means[comp]=weighted/counts[comp];var cov=0.0
            for i in range(count):let d=data[i]-means[comp];cov+=resp[comp*16+i]*d*d
            vars[comp]=cov/counts[comp]+1.0e-6
        var ll=0.0
        for i in range(count):
            let density=weights[0]*gmm_pdf(data[i],means[0],vars[0])+weights[1]*gmm_pdf(data[i],means[1],vars[1])
            ll+=log(density+1.0e-12)
        iterations=iteration+1
        if hasprev and abs(ll-prevll)<tolerance:break
        prevll=ll;hasprev=True
    out[0]=UInt8(iterations)
    for i in range(count):
        let p0=weights[0]*gmm_pdf(data[i],means[0],vars[0]);let p1=weights[1]*gmm_pdf(data[i],means[1],vars[1])
        out[i+1]=UInt8(0 if p0>=p1 else 1)
    return Int64(count+1)
