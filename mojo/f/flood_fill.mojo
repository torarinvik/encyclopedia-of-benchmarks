from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn flood_write(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[offset+b]=UInt8((bits>>(8*b))&255)

@export("flood_fill")
fn flood_fill(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
              output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<6 or length>1030:return -1
    let w=input[0];let h=input[1];let sx=input[2];let sy=input[3];let fresh=input[4];let target=input[5]
    if w<1 or w>32 or h<1 or h>32 or fresh< -2147483648 or fresh>2147483647 or target< -2147483648 or target>2147483647 or fresh==target:return -1
    if Int(length)!=6+Int(w*h) or sx<0 or sx>=w or sy<0 or sy>=h:return -1
    let cells=Int(w*h)
    var image=InlineArray[Int64,1024](fill=0)
    for i in range(cells):
        let v=input[6+i]
        if v< -2147483648 or v>2147483647:return -1
        image[i]=v
    let start=Int(sx*h+sy)
    if image[start]==target:
        var stack=InlineArray[Int32,1024](fill=0)
        var top=1;stack[0]=Int32(start);image[start]=fresh
        while top>0:
            top-=1;let index=Int(stack[top]);let x=index//Int(h);let y=index%Int(h)
            for dx in range(-1,2):
                for dy in range(-1,2):
                    if dx==0 and dy==0:continue
                    let nx=x+dx;let ny=y+dy
                    if nx<0 or nx>=Int(w) or ny<0 or ny>=Int(h):continue
                    let next=nx*Int(h)+ny
                    if image[next]==target:image[next]=fresh;stack[top]=Int32(next);top+=1
    let bytes=cells*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(cells):flood_write(output,i*8,image[i])
    return Int64(bytes)
