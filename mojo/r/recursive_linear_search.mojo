from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn rls_rec(v:InlineArray[Int64,64],left:Int,right:Int,target:Int64)->Int64:
    if left>right:return -1
    if v[left]==target:return Int64(left)
    if v[right]==target:return Int64(right)
    return rls_rec(v,left+1,right-1,target)
@export("recursive_linear_search")
fn recursive_linear_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>66 or v[0]<2 or v[0]>64 or n!=c_size_t(v[0]+2) or v[1] < -2147483648 or v[1]>2147483647:return -1
    let count=Int(v[0]);var a=InlineArray[Int64,64](fill=0)
    for i in range(count):
        if v[i+2] < -2147483648 or v[i+2]>2147483647:return -1
        a[i]=v[i+2]
        for j in range(i):if a[j]==a[i]:return -1
    return rls_rec(a,0,count-1,v[1])
