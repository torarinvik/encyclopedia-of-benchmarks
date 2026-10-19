from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mdp_solve(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int)->InlineArray[Int64,2]:
    if n==1:return InlineArray[Int64,2](v[0],v[0])
    let left_n=n/2;let left=mdp_solve(v,left_n);let right=mdp_solve(v+left_n,n-left_n)
    var min_left=v[0];var max_right=v[left_n]
    for i in range(1,left_n):if v[i]<min_left:min_left=v[i]
    for i in range(left_n+1,n):if v[i]>max_right:max_right=v[i]
    let cross=max_right-min_left;let right_diff=right[1]-right[0];let left_diff=left[1]-left[0]
    if right_diff>cross and right_diff>left_diff:return right
    if left_diff>cross:return left
    return InlineArray[Int64,2](min_left,max_right)
fn mdp_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("max_difference_pair")
fn max_difference_pair(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>128 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0])
    for i in range(count):if v[i+1]< -1000000 or v[i+1]>1000000:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let result=mdp_solve(v+1,count)
    mdp_store(out,0,result[0]);mdp_store(out,8,result[1]);return 16
