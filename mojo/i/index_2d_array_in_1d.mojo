from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("index_2d_array_in_1d")
fn index_2d_array_in_1d(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4:return -1
    let rows=input[0];let cols=input[1];let index=input[2]
    if rows<1 or rows>32 or cols<1 or cols>32:return -1
    let cells=Int(rows*cols)
    if Int(length)!=cells+3 or index<0 or index>=rows*cols:return -1
    for i in range(cells):
        if input[3+i]<0 or input[3+i]>1000000:return -1
    let row=Int(index//cols);let col=Int(index%cols)
    return input[3+row*Int(cols)+col]
