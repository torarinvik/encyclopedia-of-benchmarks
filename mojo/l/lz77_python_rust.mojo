from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lzpr_store(mut o:InlineArray[UInt8,1536],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("lz77_python_rust_compress")
fn lz77_python_rust_compress(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let size=Int(v[0])
    for i in range(size):if v[i+1]<32 or v[i+1]>126:return -1
    if size>0:
        var occurrences=0
        for i in range(size):if v[i+1]==v[size]:occurrences+=1
        if occurrences!=1:return -1
    var bytes=InlineArray[UInt8,1536](fill=UInt8(0));var tokens=0;var cur=0
    while cur<size:
        var offset_best=0;var length_best=0;let start=if cur>7:cur-7 else:0
        for candidate in range(start,cur):
            let offset=cur-candidate;var ml=0
            while cur+ml<size:
                var source=candidate+ml
                if source>=cur:source=candidate+(ml%offset)
                if v[source+1]!=v[cur+ml+1]:break
                ml+=1
            if ml>=length_best:offset_best=offset;length_best=ml
        if length_best>=size-cur:return -1
        let indicator=v[cur+length_best+1];let at=tokens*24
        lzpr_store(bytes,at,Int64(offset_best));lzpr_store(bytes,at+8,Int64(length_best));lzpr_store(bytes,at+16,indicator)
        tokens+=1;cur+=length_best+1
    let total=tokens*24
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total):return -2
    for i in range(total):o[i]=bytes[i]
    return Int64(total)
