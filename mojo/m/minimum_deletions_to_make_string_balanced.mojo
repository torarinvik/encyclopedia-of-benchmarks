from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_deletions_to_make_string_balanced")
fn minimum_deletions_to_make_string_balanced(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var a:Int64=0;var b:Int64=0
    for i in range(Int(n)):
        let x=v[i]
        if x<0 or x>1:return -1
        let na=a+(1 if x==1 else 0);let with_a=b+(1 if x==0 else 0);b=if a<with_a:a else:with_a;a=na
    return if a<b:a else:b
