from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("is_contains_unique_chars")
fn is_contains_unique_chars(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        if values[i]<0 or values[i]>127:return -1
    var seen=InlineArray[UInt64,2](fill=0)
    for i in range(Int(length)):
        let value=Int(values[i]);let word=value//64;let mask=UInt64(1)<<UInt(value%64)
        if (seen[word]&mask)!=0:return 0
        seen[word]|=mask
    return 1
