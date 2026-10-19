from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lzj_store(mut o:InlineArray[UInt8,1536],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("lz77_java_compress")
fn lz77_java_compress(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let size=Int(v[0])
    for i in range(size):if v[i+1]<32 or v[i+1]>126:return -1
    var bytes=InlineArray[UInt8,1536](fill=UInt8(0));var tokens=0;var cur=0
    while cur<size:
        var best_dist=0;var best_len=0;let start=if cur>4096:cur-4096 else:0;let end=if cur+16<size:cur+16 else:size
        for candidate in range(start,cur):
            var ml=0
            while cur+ml<end:
                var source=candidate+ml
                if source>=cur:source=candidate+(ml%(cur-candidate))
                if v[source+1]!=v[cur+ml+1]:break
                ml+=1
            if ml>best_len:best_dist=cur-candidate;best_len=ml
        let next:Int64=if cur+best_len<size:v[cur+best_len+1] else:0
        lzj_store(bytes,tokens*24,Int64(best_dist));lzj_store(bytes,tokens*24+8,Int64(best_len));lzj_store(bytes,tokens*24+16,next)
        tokens+=1;cur+=if next==0:best_len else:best_len+1
    let total=tokens*24
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total):return -2
    for i in range(total):o[i]=bytes[i]
    return Int64(total)
