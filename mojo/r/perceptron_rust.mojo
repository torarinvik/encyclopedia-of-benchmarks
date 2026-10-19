from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite,trunc
fn pru_integer(x:Float64,lo:Int,hi:Int)->Bool:return isfinite(x) and x>=Float64(lo) and x<=Float64(hi) and x==trunc(x)
@export("perceptron_rust")
fn perceptron_rust(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<9 or n>62:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if not pru_integer(v[0],0,12) or not (v[1]==0.25 or v[1]==0.5 or v[1]==0.75 or v[1]==1.0) or not pru_integer(v[2],2,8) or not pru_integer(v[3],1,4):return -1
    let iterations=Int(v[0]);let samples=Int(v[2]);let features=Int(v[3]);let labels_at=4+samples*features;let qidx=labels_at+samples
    if n<=c_size_t(qidx) or not pru_integer(v[qidx],1,4):return -1
    let queries=Int(v[qidx]);if n!=c_size_t(qidx+1+queries*features) or n>61:return -1
    var x=InlineArray[Float64,32](fill=0.0);var labels=InlineArray[Float64,8](fill=0.0);var query=InlineArray[Float64,16](fill=0.0)
    for i in range(samples*features):if not pru_integer(v[4+i],-2,2):return -1;x[i]=v[4+i]
    for i in range(samples):if v[labels_at+i]!= -1.0 and v[labels_at+i]!=1.0:return -1;labels[i]=v[labels_at+i]
    for i in range(queries*features):if not pru_integer(v[qidx+1+i],-2,2):return -1;query[i]=v[qidx+1+i]
    var weights=InlineArray[Float64,4](fill=0.0);var bias:Float64=0.0
    for it in range(iterations):
        var mistakes=0
        for row in range(samples):
            var score:Float64=0.0
            for j in range(features):score+=weights[j]*x[row*features+j]
            score+=bias;let pred=if score>=0:1.0 else: -1.0
            if pred!=labels[row]:
                mistakes+=1
                for j in range(features):weights[j]+=v[1]*labels[row]*x[row*features+j]
                bias+=v[1]*labels[row]
        if mistakes==0:break
    var staged=InlineArray[Float64,11](fill=0.0);var pos=0;staged[pos]=Float64(features);pos+=1
    for j in range(features):staged[pos]=weights[j];pos+=1
    staged[pos]=bias;pos+=1;staged[pos]=Float64(queries);pos+=1
    for row in range(queries):
        var score:Float64=0.0
        for j in range(features):score+=weights[j]*query[row*features+j]
        score+=bias;staged[pos]=if score>=0:1.0 else: -1.0;pos+=1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):o[i]=staged[i]
    return Int64(pos)
