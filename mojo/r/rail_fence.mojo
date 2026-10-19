from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rail_for(pos:Int,rails:Int)->Int:
    let period=2*(rails-1);let phase=pos%period
    return if phase<rails:phase else:period-phase
@export("rail_fence")
fn rail_fence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259 or v[0]<0 or v[0]>1 or v[1]<2 or v[1]>8 or v[2]<0 or v[2]>256:return -1
    let mode=Int(v[0]);let rails=Int(v[1]);let size=Int(v[2])
    if n!=c_size_t(size+3):return -1
    for i in range(size):if v[3+i]<0 or v[3+i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size):return -2
    if mode==0:
        var at=0
        for r in range(rails):
            for p in range(size):if rail_for(p,rails)==r:o[at]=UInt8(v[p+3]);at+=1
    else:
        var counts=InlineArray[Int64,8](fill=0);var starts=InlineArray[Int64,8](fill=0);var used=InlineArray[Int64,8](fill=0)
        for p in range(size):counts[rail_for(p,rails)]+=1
        for r in range(1,rails):starts[r]=starts[r-1]+counts[r-1]
        for p in range(size):let r=rail_for(p,rails);o[p]=UInt8(v[3+Int(starts[r]+used[r])]);used[r]+=1
    return Int64(size)
