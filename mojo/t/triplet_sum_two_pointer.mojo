from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("triplet_sum_two_pointer")
fn triplet_sum_two_pointer(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025 or a[0]< -3000000 or a[0]>3000000:return -1
    let count=Int(n-1)
    var vals=InlineArray[Int64,1024]()
    for i in range(count):
        if a[i+1]< -1000000 or a[i+1]>1000000:return -1
        vals[i]=a[i+1]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<24:return -2
    for i in range(1,count):
        let v=vals[i];var j=i
        while j>0 and vals[j-1]>v:vals[j]=vals[j-1];j-=1
        vals[j]=v
    var res=InlineArray[Int64,3]();var found=false
    for i in range(count-2):
        var l=i+1;var r=count-1
        while l<r:
            let s=vals[i]+vals[l]+vals[r]
            if s==a[0]:res[0]=vals[i];res[1]=vals[l];res[2]=vals[r];found=true;break
            elif s<a[0]:l+=1
            else:r-=1
        if found:break
    for i in range(3):
        let bits=bitcast[UInt64](res[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return 3
