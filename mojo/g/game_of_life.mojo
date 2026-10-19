from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("game_of_life")
fn game_of_life(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let side=Int(v[0]);if side<0 or side>32 or n!=c_size_t(1+side*side):return -1
    let cells=side*side
    for i in range(cells):if v[i+1]!=0 and v[i+1]!=1:return -1
    if cap<c_size_t(cells) or (cells>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var stage=InlineArray[UInt8,1024](fill=0)
    for r in range(side):
        for c in range(side):
            var neighbors=0
            for dr in range(-1,2):
                for dc in range(-1,2):
                    let rr=r+dr;let cc=c+dc
                    if (dr!=0 or dc!=0) and rr>=0 and rr<side and cc>=0 and cc<side and v[1+rr*side+cc]==1:neighbors+=1
            let alive=v[1+r*side+c]==1
            stage[r*side+c]=UInt8(1 if (alive and (neighbors==2 or neighbors==3)) or ((not alive) and neighbors==3) else 0)
    for i in range(cells):out[i]=stage[i]
    return Int64(cells)
