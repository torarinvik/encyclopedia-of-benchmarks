from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindrome_linked_list")
fn palindrome_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>9:return -1
    var l=0;var r=Int(n)
    while l<r:r-=1;if v[l]!=v[r]:return 0;l+=1
    return 1
