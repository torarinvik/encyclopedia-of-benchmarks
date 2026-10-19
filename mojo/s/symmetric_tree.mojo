from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAX_TREE=1023
fn symmetric_mirror(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,left:Int64,right:Int64)->Int64:
    if left== -1 or right== -1:return 1 if left==right else 0
    if left<0 or right<0 or left>=n or right>=n:return -1
    let li=Int(left);let ri=Int(right)
    if v[li*3]!=v[ri*3]:return 0
    let ll=v[li*3+1];let lr=v[li*3+2];let rl=v[ri*3+1];let rr=v[ri*3+2]
    if ll< -1 or (ll>=0 and ll>=n) or lr< -1 or (lr>=0 and lr>=n) or rl< -1 or (rl>=0 and rl>=n) or rr< -1 or (rr>=0 and rr>=n):return -1
    let outer=symmetric_mirror(v,n,ll,rr)
    if outer!=1:return outer
    return symmetric_mirror(v,n,lr,rl)
@export("symmetric_tree")
fn symmetric_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,root:Int64) abi("C")->Int64:
    if n>MAX_TREE:return -1
    if n==0:return 1 if root== -1 else -1
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=n:return -1
    let i=Int(root);let left=v[i*3+1];let right=v[i*3+2]
    if left< -1 or (left>=0 and left>=n) or right< -1 or (right>=0 and right>=n):return -1
    return symmetric_mirror(v,Int(n),left,right)
