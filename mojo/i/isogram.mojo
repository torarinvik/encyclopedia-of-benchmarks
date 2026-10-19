from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("isogram")
fn isogram(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var seen=InlineArray[Bool,26](fill=False)
    for i in range(Int(length)):
        var c=values[i]
        if c==32:continue
        if c>=65 and c<=90:c+=32
        if c<97 or c>122:return -1
        let idx=Int(c-97)
        if seen[idx]:return 0
        seen[idx]=True
    return 1
