from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mines_store(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p+b]=UInt8((u>>(8*b))&255)
@export("minesweeper")
fn minesweeper(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1026:return -1
    let rows=v[0];let cols=v[1]
    if rows<1 or rows>32 or cols<1 or cols>32 or Int(n)!=2+Int(rows*cols):return -1
    let r=Int(rows);let c=Int(cols);let count=r*c;var neighbors=InlineArray[Int64,1024](fill=0)
    for i in range(count):if v[i+2]!=0 and v[i+2]!=1:return -1
    for y in range(r):
        for x in range(c):
            var mines=0
            for dy in range(-1,2):
                for dx in range(-1,2):
                    if dx==0 and dy==0:continue
                    let yy=y+dy;let xx=x+dx
                    if yy>=0 and yy<r and xx>=0 and xx<c and v[2+yy*c+xx]==1:mines+=1
            neighbors[y*c+x]=Int64(mines)
    let bytes=8+count*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mines_store(out,0,Int64(count))
    for i in range(count):mines_store(out,8+8*i,neighbors[i])
    return Int64(bytes)
