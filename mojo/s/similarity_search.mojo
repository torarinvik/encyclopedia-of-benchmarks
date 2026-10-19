from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
fn sim_put64(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:UInt64):
    for b in range(8):o[p+b]=UInt8((v>>UInt(8*b))&255)
@export("similarity_search")
fn similarity_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>643:return -1
    let rows=a[0];let queries=a[1];let feats=a[2]
    if rows<1 or rows>32 or queries<1 or queries>8 or feats<1 or feats>16 or n!=c_size_t(3+(rows+queries)*feats):return -1
    for i in range(3,Int(n)):if a[i]< -1000000 or a[i]>1000000:return -1
    let rec=16+8*Int(feats);let bytes=Int(queries)*rec;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[UInt8,1152]()
    for q in range(Int(queries)):
        var best=0;var sum=0.0
        for f in range(Int(feats)):let d=Float64(a[3+f])/1e6-Float64(a[3+Int(rows*feats)+q*Int(feats)+f])/1e6;sum+=d*d
        var dist=sqrt(sum)
        for r in range(1,Int(rows)):
            sum=0.0
            for f in range(Int(feats)):let d=Float64(a[3+r*Int(feats)+f])/1e6-Float64(a[3+Int(rows*feats)+q*Int(feats)+f])/1e6;sum+=d*d
            let d=sqrt(sum);if d<dist:best=r;dist=d
        let p=q*rec;sim_put64(staged.unsafe_ptr(),p,UInt64(best));sim_put64(staged.unsafe_ptr(),p+8,bitcast[UInt64](dist))
        for f in range(Int(feats)):sim_put64(staged.unsafe_ptr(),p+16+8*f,bitcast[UInt64](a[3+best*Int(feats)+f]))
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
