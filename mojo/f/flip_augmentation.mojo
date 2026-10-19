from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn flip_store32(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt32(Int32(value))
    for b in range(4):out[at+b]=UInt8((bits>>(8*b))&255)

@export("flip_augmentation")
fn flip_augmentation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                     output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>340:return -1
    let w=input[0];let h=input[1];let typ=input[2];let boxes=input[3]
    if w<1 or w>16 or h<1 or h>16 or (typ!=0 and typ!=1) or boxes<0 or boxes>16:return -1
    let pixels=Int(w*h)
    if Int(length)!=4+pixels+5*Int(boxes):return -1
    for i in range(pixels):
        if input[4+i]<0 or input[4+i]>255:return -1
    for box in range(Int(boxes)):
        let base=4+pixels+5*box
        if input[base]<0 or input[base]>2147483647:return -1
        for f in range(1,5):
            if input[base+f]<0 or input[base+f]>1000000:return -1
    let bytes=pixels+20*Int(boxes)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for row in range(Int(h)):
        for col in range(Int(w)):
            var sr=row;var sc=col
            if typ==0:sr=Int(h)-1-row
            else:sc=Int(w)-1-col
            output[row*Int(w)+col]=UInt8(input[4+sr*Int(w)+sc])
    for box in range(Int(boxes)):
        let base=4+pixels+5*box;let dest=pixels+20*box
        for field in range(5):
            var value=input[base+field]
            if typ==1 and field==1:value=1000000-value
            if typ==0 and field==2:value=1000000-value
            flip_store32(output,dest+4*field,value)
    return Int64(bytes)
