from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("lsb_image_steganography")
fn lsb_image_steganography(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                           output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>292:return -1
    let rows=input[0];let cols=input[1];let msg=input[2]
    if rows<1 or rows>16 or cols<1 or cols>16 or msg<0 or msg>32:return -1
    let pixels=Int(rows*cols);let message=Int(msg)
    if message*8>pixels or Int(length)!=3+pixels+message:return -1
    for i in range(pixels):
        if input[3+i]<0 or input[3+i]>254:return -1
    for i in range(message):
        if input[3+pixels+i]<0 or input[3+pixels+i]>127:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(pixels):return -2
    var staged=InlineArray[UInt8,256](fill=0)
    for i in range(pixels):staged[i]=UInt8(input[3+i])
    var bit_index=0
    for i in range(message):
        let byte=UInt32(input[3+pixels+i])
        for shift in range(7,-1,-1):
            let bit=(byte>>UInt(shift))&1
            let pixel=UInt32(staged[bit_index])
            staged[bit_index]=UInt8(pixel+((pixel&1)^bit))
            bit_index+=1
    for i in range(pixels):output[i]=staged[i]
    return Int64(pixels)
