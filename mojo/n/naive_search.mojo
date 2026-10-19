from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("naive_search")
fn naive_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let tn=a[0];let pn=a[1]
    if tn<0 or tn>255 or pn<0 or pn>255 or n!=c_size_t(2+tn+pn):return -1
    for i in range(2,Int(n)):if a[i]<1 or a[i]>127:return -1
    var ans=InlineArray[UInt8,256]();var cnt=0
    if pn==0:
        for i in range(Int(tn)+1):ans[cnt]=UInt8(i);cnt+=1
    elif pn<=tn:
        for i in range(Int(tn-pn+1)):
            var ok=True
            for j in range(Int(pn)):if a[2+i+j]!=a[2+Int(tn)+j]:ok=False;break
            if ok:ans[cnt]=UInt8(i);cnt+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(cnt):return -2
    for i in range(cnt):o[i]=ans[i]
    return cnt
