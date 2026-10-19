from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_spain_national_id")
fn is_spain_national_id(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or (length!=9 and length!=10):return -1
    for i in range(Int(length)):
        if input[i]<0 or input[i]>127:return -1
    if length==10 and input[8]!=45:return -1
    var number:Int64=0
    for i in range(8):
        if input[i]<48 or input[i]>57:return -1
        number=number*10+input[i]-48
    var letter=input[Int(length)-1]
    if letter>=97 and letter<=122:letter-=32
    if letter<65 or letter>90:return -1
    let table="TRWAGMYFPDXBNJZSQVHLCKE"
    return 1 if Int64(table.as_bytes()[Int(number%23)])==letter else 0
