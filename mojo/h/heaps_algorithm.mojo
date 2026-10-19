from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("heaps_algorithm")
fn heaps_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>6:return -1
    let count=Int(n);var fact=1
    for j in range(2,count+1):fact*=j
    let bytes=fact*count*8
    if cap<c_size_t(bytes) or out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var vals=InlineArray[Int64,6](fill=0);var ks=InlineArray[Int,8](fill=0);var phase=InlineArray[Int,8](fill=0);var depth=0;ks[0]=count
    for j in range(count):vals[j]=a[j]
    var rows=0
    while depth>=0:
        if ks[depth]<=1:
            for j in range(count):
                let u=bitcast[UInt64](vals[j])
                for b in range(8):out[(rows*count+j)*8+b]=UInt8((u>>UInt(8*b))&255)
            rows+=1;depth-=1
        elif phase[depth]==0:
            phase[depth]=1;depth+=1;ks[depth]=ks[depth-1]-1;phase[depth]=0
        elif phase[depth]<ks[depth]:
            let idx=phase[depth]-1;let size=ks[depth];let swap=idx if size%2==0 else 0;let end=size-1
            let t=vals[swap];vals[swap]=vals[end];vals[end]=t
            phase[depth]+=1;depth+=1;ks[depth]=ks[depth-1]-1;phase[depth]=0
        else:depth-=1
    return Int64(rows)
