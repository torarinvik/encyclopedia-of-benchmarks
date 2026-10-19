from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_valid_parentheses")
fn longest_valid_parentheses(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]!=40 and v[i]!=41:return -1
    var ends=InlineArray[Int64,4096](fill=0);var best=0
    for rem in range(Int(n)):
        let i=Int(n)-1-rem
        if v[i]==40:
            if i+1<Int(n) and v[i+1]==41:
                ends[i]=Int64(i+2)
                if i+2<Int(n) and ends[i+2]>ends[i]:ends[i]=ends[i+2]
            elif i+1<Int(n):
                let inner=Int(ends[i+1])
                if inner>0 and inner<Int(n) and v[inner]==41:
                    ends[i]=Int64(inner+1)
                    if inner+1<Int(n) and ends[inner+1]>ends[i]:ends[i]=ends[inner+1]
        if ends[i]>i and ends[i]-i>best:best=Int(ends[i])-i
    return Int64(best)
