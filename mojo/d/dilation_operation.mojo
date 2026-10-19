from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn dilation_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int):
    let bits=UInt32(value)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(b*8))&255)
@export("dilation_operation")
fn dilation_operation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<12 or length>267:return -1
    let rv=input[0];let cv=input[1]
    if rv<1 or rv>16 or cv<1 or cv>16:return -1
    let rows=Int(rv);let cols=Int(cv);let cells=rows*cols
    if length!=c_size_t(2+cells+9):return -1
    for i in range(cells+9):if input[2+i]<0 or input[2+i]>1:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(cells*4):return -2
    for y in range(rows):
        for x in range(cols):
            var total=0
            for ky in range(3):
                for kx in range(3):
                    let iy=y+ky-1;let ix=x+kx-1
                    if iy>=0 and iy<rows and ix>=0 and ix<cols:total+=Int(input[2+iy*cols+ix]*input[2+cells+ky*3+kx])
            dilation_put(out,(y*cols+x)*4,1 if total>0 else 0)
    return Int64(cells)
