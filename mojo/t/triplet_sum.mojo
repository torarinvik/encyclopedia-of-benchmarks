from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn put_triplet(out:UnsafePointer[UInt8,MutAnyOrigin],vals:InlineArray[Int64,3]):
    for i in range(3):
        let bits=bitcast[UInt64](vals[i])
        for b in range(8):out[i*8+b]=UInt8((bits>>UInt(8*b))&255)
@export("triplet_sum")
fn triplet_sum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>11 or a[0]< -3000000 or a[0]>3000000:return -1
    for i in range(1,Int(n)):if a[i]< -1000000 or a[i]>1000000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<24:return -2
    var res=InlineArray[Int64,3]();var found=false
    for i in range(Int(n-1)):
        if found:break
        for j in range(Int(n-1)):
            if found:break
            if i==j:continue
            for k in range(Int(n-1)):
                if k==i or k==j:continue
                if a[i+1]+a[j+1]+a[k+1]==a[0]:
                    res[0]=a[i+1];res[1]=a[j+1];res[2]=a[k+1]
                    if res[0]>res[1]:let t=res[0];res[0]=res[1];res[1]=t
                    if res[1]>res[2]:let t=res[1];res[1]=res[2];res[2]=t
                    if res[0]>res[1]:let t=res[0];res[0]=res[1];res[1]=t
                    found=true;break
    put_triplet(o,res);return 3
