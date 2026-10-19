from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn alnum(x:Int64)->Bool:return (x>=48 and x<=57) or (x>=65 and x<=90) or (x>=97 and x<=122)
fn lower_ascii(x:Int64)->Int64:return x+32 if x>=65 and x<=90 else x
@export("valid_palindrome")
fn valid_palindrome(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var left=0;var right=Int(n)
    while left<right:
        while left<right and not alnum(v[left]):left+=1
        while left<right and not alnum(v[right-1]):right-=1
        if left<right and lower_ascii(v[left])!=lower_ascii(v[right-1]):return 0
        left+=1;right-=1
    return 1
