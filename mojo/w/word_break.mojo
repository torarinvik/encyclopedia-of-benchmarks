from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("word_break")
fn word_break(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1122:return -1
    let tl=a[0];let wc=a[1]
    if tl<0 or tl>64 or wc<0 or wc>32 or n!=c_size_t(2+tl+33*wc):return -1
    for i in range(Int(tl)):if a[2+i]<1 or a[2+i]>26:return -1
    let base=2+Int(tl)
    for wi in range(Int(wc)):
        let p=base+wi*33;let wl=a[p]
        if wl<1 or wl>32:return -1
        for j in range(32):
            let x=a[p+1+j]
            if j<Int(wl):
                if x<1 or x>26:return -1
            elif x!=0:return -1
    var dp=InlineArray[Bool,65]();dp[0]=True
    for start in range(Int(tl)):
        if not dp[start]:continue
        for wi in range(Int(wc)):
            let p=base+wi*33;let wl=Int(a[p])
            if start+wl>Int(tl):continue
            var same=true
            for j in range(wl):if a[2+start+j]!=a[p+1+j]:same=false
            if same:dp[start+wl]=True
    return 1 if dp[Int(tl)] else 0
