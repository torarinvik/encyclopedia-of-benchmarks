from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn image_conv_store(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[offset+b]=UInt8((bits>>(8*b))&255)

@export("image_convolution")
fn image_convolution(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                     output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>308:return -1
    let side=input[0];let ks=input[1]
    if side<1 or side>16 or ks<1 or ks>7 or ks%2==0:return -1
    let cells=Int(side*side);let kn=Int(ks*ks)
    if Int(length)!=2+cells+kn:return -1
    for i in range(cells):
        if input[2+i]<0 or input[2+i]>255:return -1
    for i in range(kn):
        if input[2+cells+i]< -16 or input[2+cells+i]>16:return -1
    let bytes=cells*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let radius=Int(ks//2)
    for y in range(Int(side)):
        for x in range(Int(side)):
            var total:Int64=0
            for ky in range(Int(ks)):
                var sy=y+ky-radius
                if sy<0:sy=0
                if sy>=Int(side):sy=Int(side)-1
                for kx in range(Int(ks)):
                    var sx=x+kx-radius
                    if sx<0:sx=0
                    if sx>=Int(side):sx=Int(side)-1
                    let pixel=input[2+sy*Int(side)+sx]
                    let weight=input[2+cells+ky*Int(ks)+kx]
                    total+=pixel*weight
            image_conv_store(output,(y*Int(side)+x)*8,total)
    return Int64(bytes)
