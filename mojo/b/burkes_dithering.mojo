from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn burkes_div32(value:Int)->Int:
    return -((-value)//32) if value<0 else value//32

@export("burkes_dithering")
fn burkes_dithering(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>149:return -1
    let side=input[0];let threshold=input[1]
    if side<1 or side>7 or threshold<1 or threshold>254 or length!=c_size_t(2+3*side*side):return -1
    for i in range(2,Int(length)):
        if input[i]<0 or input[i]>255:return -1
    let n=Int(side);let stride=n+4
    var errors=List[Int](length=(n+1)*stride,fill=0);var white:UInt64=0
    for y in range(n):
        for x in range(n):
            let ix=2+3*(y*n+x)
            let gray=Int((114*input[ix]+587*input[ix+1]+299*input[ix+2])/1000)
            let adjusted=gray+errors[y*stride+x]
            let is_white=Int(threshold)<=adjusted
            let delta=adjusted-(255 if is_white else 0)
            if is_white:white|=UInt64(1)<<UInt(y*n+x)
            errors[y*stride+x+1]+=burkes_div32(8*delta);errors[y*stride+x+2]+=burkes_div32(4*delta)
            errors[(y+1)*stride+x]+=burkes_div32(8*delta);errors[(y+1)*stride+x+1]+=burkes_div32(4*delta);errors[(y+1)*stride+x+2]+=burkes_div32(2*delta)
            if x>=1:errors[(y+1)*stride+x-1]+=burkes_div32(4*delta)
            if x>=2:errors[(y+1)*stride+x-2]+=burkes_div32(2*delta)
    return bitcast[Int64](white)
