from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime INVALID_TREE= -9223372036854775808
fn kth_bst_visit(a:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,node:Int64,mut rem:Int64)->Int64:
    if node==-1:return -1
    if node<0 or node>=n:return INVALID_TREE
    let i=Int(node);let value=a[3*i];let left=a[3*i+1];let right=a[3*i+2]
    if value<0 or value>10000 or left< -1 or right< -1 or left>=n or right>=n:return INVALID_TREE
    let lr=kth_bst_visit(a,n,left,rem)
    if lr>=0 or lr==INVALID_TREE:return lr
    rem-=1
    if rem==0:return value
    return kth_bst_visit(a,n,right,rem)
@export("kth_smallest_bst")
fn kth_smallest_bst(a:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64,k:Int64) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or count==0 or count>1023 or root<0 or root>=Int64(count) or k<1 or k>Int64(count):return -1
    var rem=k;let result=kth_bst_visit(a,Int(count),root,rem)
    return -1 if result<0 else result
