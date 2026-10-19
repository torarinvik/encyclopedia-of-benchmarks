from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("sock_merchant")
fn sock_merchant(colors:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>512 or (length>0 and colors==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var counts=InlineArray[Int32,4096](fill=0)
    for i in range(Int(length)):
        let color=colors[i]
        if color<0 or color>=4096:return -1
        counts[Int(color)]+=1
    var pairs=Int64(0)
    for color in range(4096):pairs+=Int64(counts[color]//2)
    return pairs
