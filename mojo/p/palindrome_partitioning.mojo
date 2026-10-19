from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("palindrome_partitioning")
fn palindrome_partitioning(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>256:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let length=Int(n);var pal=InlineArray[Int64,65536](fill=0);var cuts=InlineArray[Int64,256](fill=0)
    for end in range(length):
        var best=end
        for start in range(end+1):
            if v[start]==v[end] and (end-start<2 or pal[(start+1)*256+(end-1)]!=0):
                pal[start*256+end]=1
                let candidate=0 if start==0 else Int(cuts[start-1]+1)
                if candidate<best:best=candidate
        cuts[end]=Int64(best)
    let u=UInt64(cuts[length-1]);for b in range(8):o[b]=UInt8((u>>(8*b))&255)
    return 1
