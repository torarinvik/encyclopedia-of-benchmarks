from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mcv_impl(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t,es:Bool)->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<45 or n>198:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let sims=Int(v[3]);let rc=Int(v[4])
    if v[0]<100.0 or v[0]>1000000.0 or v[1]<0.5 or v[1]>0.95 or v[2]<1.0 or v[2]>10.0 or sims<20 or sims>128 or rc<20 or rc>64 or v[3]!=Float64(sims) or v[4]!=Float64(rc) or Int(n)!=5+rc+sims:return -1
    var rets=InlineArray[Float64,64](fill=0.0);var simsval=InlineArray[Float64,128](fill=0.0);var sum=0.0
    for i in range(rc):let x=v[5+i];if x < -0.25 or x>0.25:return -1;rets[i]=x;sum+=x
    for i in range(sims):let x=v[5+rc+i];if x < -3.0 or x>3.0:return -1;simsval[i]=x
    let mean=sum/Float64(rc);var ss=0.0
    for i in range(rc):let d=rets[i]-mean;ss+=d*d
    let sd=sqrt(ss/Float64(rc-1));if not is_finite(sd) or sd==0.0:return -1
    for i in range(sims):simsval[i]=mean+sd*simsval[i]
    for i in range(1,sims):let x=simsval[i];var j=i;while j>0 and simsval[j-1]>x:simsval[j]=simsval[j-1];j-=1;simsval[j]=x
    let tail=Int(floor((1.0-v[1])*Float64(sims)));if tail<1 or tail>sims:return -1
    var metric=0.0
    if es:
        var acc=0.0
        for i in range(tail):acc+=simsval[i]
        metric=-(acc/Float64(tail))*v[0]*sqrt(v[2])
    else:metric=-simsval[tail-1]*v[0]*sqrt(v[2])
    if not is_finite(metric):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=metric;return 1
@export("monte_carlo_var")
fn monte_carlo_var(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    return mcv_impl(v,n,o,cap,False)
