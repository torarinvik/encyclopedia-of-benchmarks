from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_subsequence")
fn is_subsequence(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>8194:return -1
    let main_n=input[0];let sub_n=input[1]
    if main_n<0 or main_n>4096 or sub_n<0 or sub_n>4096 or length!=c_size_t(2+main_n+sub_n):return -1
    for i in range(2,Int(length)):
        let cp=input[i]
        if cp<0 or cp>1114111 or (cp>=55296 and cp<=57343):return -1
    let start=2+Int(main_n);var i=0;var j=0
    while j<Int(sub_n) and i<Int(main_n):
        if input[start+j]==input[2+i]:j+=1
        i+=1
    return 1 if j==Int(sub_n) else 0
