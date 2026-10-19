from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("is_pangram")
fn is_pangram(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var seen=InlineArray[Bool,26](fill=False);var count=0
    for i in range(Int(length)):
        var c=input[i]
        if c<0 or c>127:return -1
        if c>=65 and c<=90:c+=32
        if c>=97 and c<=122:
            let j=Int(c-97)
            if not seen[j]:seen[j]=True;count+=1
    return 1 if count==26 else 0
