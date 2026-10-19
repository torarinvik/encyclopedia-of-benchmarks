from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime N=512
fn k_fnv_word(h0:UInt64,v:Int64)->UInt64:
    var h=h0;let bits=UInt64(v)
    for b in range(8):h=(h^((bits>>(8*b))&255))*1099511628211
    return h
@export("kasai_algorithm")
fn kasai_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025 or a[0]<0 or a[0]>512:return -1
    let count=Int(a[0])
    if n!=c_size_t(1+2*count):return -1
    var sa=InlineArray[Int64,N]();var rank=InlineArray[Int64,N]();var seen=InlineArray[Bool,N]();var lcp=InlineArray[Int64,N]()
    for i in range(count):
        let ch=a[1+i];let si=a[1+count+i]
        if ch<0 or ch>127 or si<0 or si>=count or seen[Int(si)]:return -1
        sa[i]=si;rank[Int(si)]=i;seen[Int(si)]=True
    for r in range(1,count):
        let l=Int(sa[r-1]);let q=Int(sa[r]);let lr=if l+1<count then rank[l+1] else -1;let qr=if q+1<count then rank[q+1] else -1
        if a[1+l]>a[1+q] or (a[1+l]==a[1+q] and lr>=qr):return -1
    var common=0
    for start in range(count):
        let r=Int(rank[start])
        if r==count-1:common=0;continue
        let nxt=Int(sa[r+1])
        while start+common<count and nxt+common<count and a[1+start+common]==a[1+nxt+common]:common+=1
        lcp[r]=common
        if common>0:common-=1
    var h=k_fnv_word(14695981039346656037,Int64(count))
    for i in range(count):h=k_fnv_word(h,lcp[i])
    return Int64(h&0x7fffffffffffffff)
