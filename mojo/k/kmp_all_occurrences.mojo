from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("kmp_all_occurrences")
fn kmp_all_occurrences(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>322 or a[0]<0 or a[0]>256 or a[1]<1 or a[1]>64 or n!=c_size_t(2+a[0]+a[1]):return -1
    let tn=Int(a[0]);let pn=Int(a[1]);let st=2+tn
    for i in range(2,Int(n)):if a[i]<0 or a[i]>127:return -1
    var pi=InlineArray[Int64,64]();var q=0
    for i in range(1,pn):
        while q>0 and a[st+i]!=a[st+q]:q=Int(pi[q-1])
        if a[st+i]==a[st+q]:q+=1
        pi[i]=q
    var ans=InlineArray[Int64,256]();var cnt=0;q=0
    for i in range(tn):
        while q>0 and a[2+i]!=a[st+q]:q=Int(pi[q-1])
        if a[2+i]==a[st+q]:q+=1
        if q==pn:ans[cnt]=i+1-pn;cnt+=1;q=Int(pi[q-1])
    let bytes=cnt*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(cnt):
        let bits=UInt64(ans[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return bytes
