from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("new_man_shanks_prime")
fn new_man_shanks_prime(n:Int64, expected:Int64) abi("C")->Int64:
    if n<1 or n>25 or expected< -2147483648 or expected>2147483647:return -1
    var prev:Int64=1;var cur:Int64=1
    if n==1:return 1 if expected==1 else 0
    for _ in range(2,Int(n)+1):
        let next=2*cur+prev;prev=cur;cur=next
    return 1 if cur==expected else 0
