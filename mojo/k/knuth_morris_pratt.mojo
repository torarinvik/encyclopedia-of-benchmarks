from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("knuth_morris_pratt")
fn knuth_morris_pratt(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>8194 or a[0]<0 or a[0]>4096 or a[1]<0 or a[1]>4096 or n!=c_size_t(2+a[0]+a[1]):return -1
    let tn=Int(a[0]);let pn=Int(a[1]);let st=2+tn
    for i in range(2,Int(n)):if a[i]<0 or a[i]>127:return -1
    if pn==0:return 0
    var pi=InlineArray[Int64,4096]();var q=0
    for i in range(1,pn):
        while q>0 and a[st+i]!=a[st+q]:q=Int(pi[q-1])
        if a[st+i]==a[st+q]:q+=1
        pi[i]=q
    q=0
    for i in range(tn):
        while q>0 and a[2+i]!=a[st+q]:q=Int(pi[q-1])
        if a[2+i]==a[st+q]:q+=1
        if q==pn:return i+1-pn
    return -1
