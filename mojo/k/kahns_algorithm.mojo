from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ka_i32(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int):
    let u=bitcast[UInt32](Int32(v))
    for b in range(4):o[at+b]=UInt8((u>>UInt(8*b))&255)
@export("kahns_algorithm")
fn kahns_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let m=a[0];if m<0 or m>128 or n!=c_size_t(1+2*m):return -1
    var vertices=InlineArray[Int64,32](fill=0);var vc=0;var from=InlineArray[Int,128](fill=0);var to=InlineArray[Int,128](fill=0);var indeg=InlineArray[Int,32](fill=0)
    for e in range(Int(m)):
        let x=a[1+2*e];let y=a[2+2*e]
        if x< -2147483648 or x>2147483647 or y< -2147483648 or y>2147483647:return -1
        for z in range(2):
            let val=if z==0:x else:y;var ix=-1
            for j in range(vc):if vertices[j]==val:ix=j
            if ix<0:
                if vc>=32:return -1
                ix=vc;vertices[vc]=val;vc+=1
            if z==0:from[e]=ix else:to[e]=ix
        indeg[to[e]]+=1
    var order=InlineArray[Int,32](fill=0);var used=InlineArray[Bool,32](fill=false)
    for step in range(vc):
        var candidate=-1;var choices=0
        for i in range(vc):if not used[i] and indeg[i]==0:candidate=i;choices+=1
        if choices!=1:return -1
        used[candidate]=true;order[step]=candidate
        for e in range(Int(m)):if from[e]==candidate:indeg[to[e]]-=1
    let bytes=vc*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(vc):ka_i32(o,i*4,Int(vertices[order[i]]))
    return Int64(bytes)
