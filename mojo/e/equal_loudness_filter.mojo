from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime EQ_A:InlineArray[Int64,11]=[1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500]
comptime EQ_B:InlineArray[Int64,11]=[60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672]
comptime EQ_HA:InlineArray[Int64,11]=[1089966811,-2146993250,1057516837,0,0,0,0,0,0,0,0]
comptime EQ_HB:InlineArray[Int64,11]=[1073619225,-2147238449,1073619225,0,0,0,0,0,0,0,0]
fn equal_loudness_step(sample:Int64,order:Int,a:InlineArray[Int64,11],b:InlineArray[Int64,11],mut x:InlineArray[Int64,10],mut y:InlineArray[Int64,10])->Int64:
    var acc=b[0]*sample
    for i in range(1,order+1):acc+=b[i]*x[i-1]-a[i]*y[i-1]
    let out=acc/a[0]
    for i in range(order-1,0,-1):x[i]=x[i-1];y[i]=y[i-1]
    if order>0:x[0]=sample;y[0]=out
    return out
@export("equal_loudness_filter")
fn equal_loudness_filter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>33:return -1
    let count=v[0]
    if count<0 or count>32 or n!=c_size_t(count+1):return -1
    for i in range(Int(count)):if v[i+1]< -1000000 or v[i+1]>1000000:return -1
    var x=InlineArray[Int64,10](fill=0);var y=InlineArray[Int64,10](fill=0);var hx=InlineArray[Int64,10](fill=0);var hy=InlineArray[Int64,10](fill=0);var out:Int64=0
    for i in range(Int(count)):
        let mid=equal_loudness_step(v[i+1],10,EQ_A,EQ_B,x,y)
        out=equal_loudness_step(mid,2,EQ_HA,EQ_HB,hx,hy)
    return out
