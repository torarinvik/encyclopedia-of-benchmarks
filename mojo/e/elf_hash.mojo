from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("elf_hash")
fn elf_hash(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>8 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var hash:UInt64=0
    for i in range(Int(length)):
        let c=values[i]
        if c<0 or c>127:return -1
        hash=(hash<<4)+UInt64(c)
        let high=hash&UInt64(0xF0000000)
        if high!=0:hash^=high>>24;hash^=high
    return Int64(hash)
