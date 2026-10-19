from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_chunked_palindrome_decomposition")
fn longest_chunked_palindrome_decomposition(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>128 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]<1 or v[i]>127:return -1
    var left=0;var right=Int(n);var chunks:Int64=0
    while left<right:
        let remaining=right-left;var matched=False
        for size in range(1,remaining/2+1):
            var equal=True
            for j in range(size):
                if v[left+j]!=v[right-size+j]:equal=False;break
            if equal:chunks+=2;left+=size;right-=size;matched=True;break
        if not matched:return chunks+1
    return chunks
