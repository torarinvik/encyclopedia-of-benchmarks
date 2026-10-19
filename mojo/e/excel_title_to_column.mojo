from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("excel_title_to_column")
fn excel_title_to_column(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>13:return -1
    let count=values[0]
    if count<1 or count>12 or length!=c_size_t(1+count):return -1
    var col:Int64=0
    for i in range(Int(count)):
        var c=values[i+1]
        if c>=97 and c<=122:c-=32
        if c<65 or c>90:return -1
        col=col*26+c-64
    return col
