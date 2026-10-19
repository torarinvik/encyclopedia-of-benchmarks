from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn part_rec(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,i:Int,target:Int64,half:Int64)->Bool:
    if target==half:return True
    if i>=n or target>half:return False
    return part_rec(v,n,i+1,target+v[i],half) or part_rec(v,n,i+1,target,half)
@export("partition")
fn partition(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>17 or v[0]<0 or v[0]>16 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var sum:Int64=0
    for i in range(count):if v[i+1]<0 or v[i+1]>1000:return -1;sum+=v[i+1]
    if sum%2!=0:return 0
    return 1 if part_rec(v+1,count,0,0,sum/2) else 0
