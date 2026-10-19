from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pg_gen(n:Int,open:Int,close:Int,mut path:InlineArray[UInt8,12],o:UnsafePointer[UInt8,MutAnyOrigin],mut index:Int):
    if open+close==2*n:
        for i in range(2*n):o[2+index*(2*n)+i]=path[i]
        index+=1;return
    if open<n:path[open+close]=40;pg_gen(n,open+1,close,mut path,o,mut index)
    if close<open:path[open+close]=41;pg_gen(n,open,close+1,mut path,o,mut index)
@export("parentheses_generator")
fn parentheses_generator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>6:return -1
    let pairs=Int(v[0]);let counts=InlineArray[Int64,7](1,1,2,5,14,42,132);let needed=2+Int(counts[pairs])*2*pairs
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    o[0]=UInt8(counts[pairs]&255);o[1]=UInt8((counts[pairs]>>8)&255);var path=InlineArray[UInt8,12](fill=0);var index=0
    pg_gen(pairs,0,0,mut path,o,mut index)
    return Int64(needed)
