from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("heaps")
fn heaps(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<0 or a[0]>7:return -1
    let count=Int(a[0]);var fact=1
    for j in range(2,count+1):fact*=j
    let bytes=fact*count
    if cap<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if count==0:return 0
    var values=InlineArray[UInt8,7](fill=0);var ks=InlineArray[Int,8](fill=0);var phases=InlineArray[Int,8](fill=0);var depth=0;ks[0]=count
    for j in range(count):values[j]=UInt8(49+j)
    var rows=0
    while depth>=0:
        if ks[depth]<=1:
            for j in range(count):out[rows*count+j]=values[j]
            rows+=1;depth-=1
        elif phases[depth]<ks[depth]:
            phases[depth]+=1;depth+=1;ks[depth]=ks[depth-1]-1;phases[depth]=0
        else:
            depth-=1
            if depth>=0:
                let size=ks[depth];let idx=phases[depth]-1;let swap=idx if size%2==1 else 0;let end=size-1
                let t=values[swap];values[swap]=values[end];values[end]=t
    return Int64(rows)
