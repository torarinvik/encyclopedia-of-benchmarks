from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("verifying_an_alien_dictionary")
fn verifying_an_alien_dictionary(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<27 or n>2127:return -1
    let wc=v[0]
    if wc<1 or wc>100:return -1
    var rank=InlineArray[Int64,26](fill=0);var seen=InlineArray[Bool,26](fill=False)
    for i in range(26):
        let c=v[1+i]
        if c<97 or c>122:return -1
        let x=Int(c-97)
        if seen[x]:return -1
        seen[x]=True;rank[x]=i
    var starts=InlineArray[Int,100](fill=0);var lens=InlineArray[Int,100](fill=0);var p=27
    for w in range(Int(wc)):
        if p>=Int(n):return -1
        let l=v[p]
        if l<1 or l>20:return -1
        p+=1
        if Int(l)>Int(n)-p:return -1
        starts[w]=p;lens[w]=Int(l)
        for j in range(Int(l)):
            if v[p+j]<97 or v[p+j]>122:return -1
        p+=Int(l)
    if p!=Int(n):return -1
    for w in range(Int(wc)-1):
        let lim=if lens[w]<lens[w+1] then lens[w] else lens[w+1]
        var decided=False
        for j in range(lim):
            let a=rank[Int(v[starts[w]+j]-97)];let b=rank[Int(v[starts[w+1]+j]-97)]
            if a<b:decided=True;break
            if a>b:return 0
        if not decided and lens[w]>lens[w+1]:return 0
    return 1
