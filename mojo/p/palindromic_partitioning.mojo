from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindromic_partitioning")
fn palindromic_partitioning(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or v[0]<1 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let m=Int(v[0]);var p=InlineArray[Int64,4096](fill=0);var cuts=InlineArray[Int64,64](fill=0)
    for end in range(m):
        if v[end+1]<0 or v[end+1]>127:return -1
        for start in range(end+1):p[start*64+end]=1 if v[start+1]==v[end+1] and (end-start<2 or p[(start+1)*64+(end-1)]!=0) else 0
    for end in range(m):
        if p[end]!=0:cuts[end]=0
        else:
            cuts[end]=64
            for start in range(1,end+1):if p[start*64+end]!=0 and cuts[start-1]+1<cuts[end]:cuts[end]=cuts[start-1]+1
    return cuts[m-1]
