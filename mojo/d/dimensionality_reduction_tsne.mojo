from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import exp,log2,exp2
@export("dimensionality_reduction_tsne")
fn dimensionality_reduction_tsne(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length!=5 or input[0]!=1.0 or input[1]!=3.0:return -1
    var x=List[Float64](capacity=3)
    for i in range(3):
        let v=input[i+2]
        if v!=v or v>100.0 or v< -100.0:return -1
        x.append(v)
    if out==UnsafePointer[Float64,MutAnyOrigin]() or capacity<3:return -2
    var d=List[Float64](length=9,fill=0.0);var p=List[Float64](length=9,fill=0.0);var q=List[Float64](length=9,fill=0.0)
    var denom=List[Float64](length=9,fill=0.0)
    var y=List[Float64](capacity=3);y.append(3.0471707975443136e-05);y.append(-1.0399841062404956e-04);y.append(7.504511958064573e-05)
    var momentum=List[Float64](length=3,fill=0.0)
    for i in range(3):
        for j in range(3):let z=x[i]-x[j];d[i*3+j]=z*z
    for i in range(3):
        var lo:Float64=0.0;var hi:Float64=0.0;var lo_set=false;var hi_set=false;var beta:Float64=1.0;var probs=List[Float64](length=3,fill=0.0)
        for it in range(50):
            var exps=List[Float64](length=3,fill=0.0);var total:Float64=0.0
            for j in range(3):
                if i!=j:exps[j]=exp(-d[i*3+j]*beta)
                total+=exps[j]
            if total==0.0:
                for j in range(3):p[i*3+j]=0.0
                break
            var entropy:Float64=0.0
            for j in range(3):
                probs[j]=exps[j]/total
                if probs[j]>0.0:entropy-=probs[j]*log2(probs[j]+1.0e-12)
            let current=exp2(entropy)
            if abs(current-1.5)<1.0e-5:
                for j in range(3):p[i*3+j]=probs[j]
                break
            if current>1.5:
                lo=beta;lo_set=true
                beta=beta*2.0 if not hi_set else (beta+hi)/2.0
            else:
                hi=beta;hi_set=true
                beta=beta/2.0 if not lo_set else (beta+lo)/2.0
            if it==49:
                for j in range(3):p[i*3+j]=probs[j]
    var high=List[Float64](length=9,fill=0.0)
    for i in range(3):
        for j in range(3):
            high[i*3+j]=(p[i*3+j]+p[j*3+i])/6.0
            if high[i*3+j]<1.0e-12:high[i*3+j]=1.0e-12
    for it in range(5):
        var total:Float64=0.0
        for i in range(3):
            for j in range(3):
                let z=y[i]-y[j]
                if i==j:denom[i*3+j]=0.0;q[i*3+j]=0.0
                else:denom[i*3+j]=1.0+z*z;q[i*3+j]=1.0/denom[i*3+j]
                total+=q[i*3+j]
        for i in range(3):
            for j in range(3):
                q[i*3+j]=(0.0 if i==j else (1.0/6.0 if total==0.0 else q[i*3+j]/total))
                if q[i*3+j]<1.0e-12:q[i*3+j]=1.0e-12
        var gradient=List[Float64](length=3,fill=0.0)
        for i in range(3):
            for j in range(3):
                if i!=j:gradient[i]+=(high[i*3+j]-q[i*3+j])*(1.0/denom[i*3+j])*(y[i]-y[j])
            gradient[i]*=4.0
        for i in range(3):momentum[i]=0.5*momentum[i]-10.0*gradient[i];y[i]+=momentum[i]
    for i in range(3):out[i]=y[i]
    return 3
