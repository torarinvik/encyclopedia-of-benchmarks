from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs, sqrt
@export("generalized_esd")
fn generalized_esd(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5:return -1
    let count=Int(v[0]);let limit=Int(v[1])
    if count<3 or count>8 or limit<1 or limit>3 or limit>count-2 or n!=c_size_t(count+2):return -1
    let critical=InlineArray[Float64,9](0.0,0.0,0.0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462)
    var vals=InlineArray[Float64,8](fill=0.0);var ids=InlineArray[Int,8](fill=0)
    for i in range(count):if v[i+2]< -10000 or v[i+2]>10000:return -1;vals[i]=Float64(v[i+2]);ids[i]=i
    var remaining=count;var accepted=0;var removed=InlineArray[Int,3](fill=0)
    for step in range(1,limit+1):
        var mean=0.0
        for i in range(remaining):mean+=vals[i]
        mean/=Float64(remaining);var ss=0.0
        for i in range(remaining):let d=vals[i]-mean;ss+=d*d
        let sd=sqrt(ss/Float64(remaining-1));if sd==0.0:break
        var worst=0;var largest= -1.0
        for i in range(remaining):let d=abs(vals[i]-mean);if d>largest:largest=d;worst=i
        removed[step-1]=ids[worst]
        if largest/sd>critical[remaining]:accepted=step
        remaining-=1;vals[worst]=vals[remaining];ids[worst]=ids[remaining]
    var mask:Int64=0
    for i in range(accepted):mask|=Int64(1)<<removed[i]
    return mask
