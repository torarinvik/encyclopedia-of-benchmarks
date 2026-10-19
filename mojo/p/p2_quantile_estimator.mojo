from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("p2_quantile_estimator")
fn p2_quantile_estimator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or v[0]<1 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1.0e300
    let count=Int(v[0]);var q=InlineArray[Float64,5](fill=0.0);var p=InlineArray[Float64,5](fill=0.0);var d=InlineArray[Float64,5](fill=0.0);var np=InlineArray[Float64,5](0.0,0.25,0.5,0.75,1.0);var seen=0
    for z in range(count):
        if v[z+1] < -2147483648 or v[z+1]>2147483647:return -1.0e300
        let x=Float64(v[z+1])
        if seen<5:
            q[seen]=x;seen+=1
            if seen==5:
                for a in range(1,5):let t=q[a];var b=a;while b>0 and q[b-1]>t:q[b]=q[b-1];b-=1;q[b]=t
                for i in range(5):p[i]=Float64(i+1);d[i]=Float64(i+1)
            continue
        var k=3
        if x<q[0]:q[0]=x;k=0
        else:
            for i in range(1,4):if x<q[i]:k=i-1;break
            if x>q[4]:q[4]=x
        for i in range(k+1,5):p[i]+=1.0
        for i in range(5):d[i]+=np[i]
        for i in range(1,4):
            let drift=d[i]-p[i];let right=drift>=1.0 and p[i+1]-p[i]>1.0;let left=drift<=-1.0 and p[i-1]-p[i]<-1.0
            if not right and not left:continue
            let direction=1.0 if right else -1.0;let l=p[i]-p[i-1];let r=p[i+1]-p[i]
            let cand=q[i]+direction/(l+r)*((l+direction)*(q[i+1]-q[i])/r+(r-direction)*(q[i]-q[i-1])/l)
            if q[i-1]<cand and cand<q[i+1]:q[i]=cand
            else:let nb=i+Int(direction);q[i]+=direction*(q[nb]-q[i])/(p[nb]-p[i])
            p[i]+=direction
    if seen<5:
        for a in range(1,count):let x=q[a];var b=a;while b>0 and q[b-1]>x:q[b]=q[b-1];b-=1;q[b]=x
        let rank=0.5*Float64(count-1);let lo=Int(rank);let hi=if lo+1<count:lo+1 else:lo
        return q[lo]+(rank-Float64(lo))*(q[hi]-q[lo])
    return q[2]
