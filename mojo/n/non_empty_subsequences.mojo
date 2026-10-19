from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn nes_walk(start:Int,depth:Int,n:Int,vals:InlineArray[Int64,8],mut path:InlineArray[Int64,8],mut staged:InlineArray[UInt8,5116],mut pos:Int,mut rows:Int):
    for i in range(start,n):
        path[depth]=vals[i]
        let bits=UInt32(depth+1)
        for b in range(4):staged[pos]=UInt8((bits>>UInt(8*b))&255);pos+=1
        for j in range(depth+1):
            let u=bitcast[UInt32](Int32(path[j]))
            for b in range(4):staged[pos]=UInt8((u>>UInt(8*b))&255);pos+=1
        rows+=1
        nes_walk(i+1,depth+1,n,vals,path,staged,pos,rows)
@export("non_empty_subsequences")
fn non_empty_subsequences(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>9:return -1
    let count=a[0]
    if count<1 or count>8 or n!=c_size_t(count+1):return -1
    var vals=InlineArray[Int64,8]();var path=InlineArray[Int64,8]()
    for i in range(Int(count)):
        let x=a[i+1]
        if x<0 or x>1114111 or (x>=55296 and x<=57343):return -1
        vals[i]=x
    var staged=InlineArray[UInt8,5116]();var pos=0;var rows=0
    nes_walk(0,0,Int(count),vals,path,staged,pos,rows)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):o[i]=staged[i]
    return Int64(rows)
