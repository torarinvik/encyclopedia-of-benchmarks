from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite,log
@export("linear_discriminant_analysis")
fn linear_discriminant_analysis(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n==0 or n>22:return -1
    let cv=v[0]
    if not isfinite(cv) or cv<2 or cv>4 or Float64(Int(cv))!=cv:return -1
    let k=Int(cv)
    if Int(n)<1+k:return -1
    var counts=InlineArray[Int64,4](fill=0);var total=0
    for i in range(k):
        let x=v[1+i]
        if not isfinite(x) or x<2 or x>6 or Float64(Int(x))!=x:return -1
        counts[i]=Int64(x);total+=Int(counts[i])
    if total>16 or Int(n)!=1+k+total:return -1
    var groups=InlineArray[Float64,24](fill=0.0);var means=InlineArray[Float64,4](fill=0.0);var p=1+k
    for c in range(k):
        var sum=0.0
        for j in range(Int(counts[c])):
            let x=v[p];p+=1
            if not isfinite(x) or x < -32 or x>32 or Float64(Int(x))!=x:return -1
            groups[c*6+j]=x;sum+=x
        means[c]=sum/Float64(counts[c])
        if Float64(Int(means[c]))!=means[c]:return -1
    var sq=0.0
    for c in range(k):
        for j in range(Int(counts[c])):
            let d=groups[c*6+j]-means[c];sq+=d*d
    let variance=(1.0/Float64(total-k))*sq
    if not isfinite(variance) or variance<=0:return -1
    var priors=InlineArray[Float64,4](fill=0.0)
    for c in range(k):priors[c]=Float64(counts[c])/Float64(total)
    var staged=InlineArray[Float64,16](fill=0.0);var outn=0
    for g in range(k):
        for j in range(Int(counts[g])):
            let x=groups[g*6+j];var best= -1.0e300;var second= -1.0e300;var winner=0
            for c in range(k):
                let score=x*(means[c]/variance)-(means[c]*means[c]/(2.0*variance))+log(priors[c])
                if score>best:second=best;best=score;winner=c
                elif score>second:second=score
            if not isfinite(best) or best-second<1.0e-8:return -1
            staged[outn]=Float64(winner);outn+=1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    for i in range(outn):out[i]=staged[i]
    return Int64(outn)
