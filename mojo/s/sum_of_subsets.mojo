from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn subsets_put64(out:UnsafePointer[UInt8,MutAnyOrigin],pos:UnsafePointer[Int,MutAnyOrigin],value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[pos[0]]=UInt8((bits>>UInt(b*8))&255);pos[0]+=1
fn subsets_visit(nums:UnsafePointer[Int64,MutAnyOrigin],n:Int,target:Int64,start:Int,current:Int64,remaining:Int64,path:UnsafePointer[Int64,MutAnyOrigin],depth:Int,out:UnsafePointer[UInt8,MutAnyOrigin],pos:UnsafePointer[Int,MutAnyOrigin],count:UnsafePointer[Int,MutAnyOrigin]):
    if current>target or current+remaining<target:return
    if current==target:
        subsets_put64(out,pos,Int64(depth));count[0]+=1
        for i in range(depth):subsets_put64(out,pos,path[i])
        return
    for i in range(start,n):
        path[depth]=nums[i]
        subsets_visit(nums,n,target,i+1,current+nums[i],remaining-nums[i],path,depth+1,out,pos,count)
@export("sum_of_subsets")
fn sum_of_subsets(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let nn=v[0];let target=v[1]
    if nn<0 or nn>10 or n!=c_size_t(nn+2) or target<0 or target>250:return -1
    var nums=InlineArray[Int64,10](fill=0);var remaining:Int64=0
    for i in range(Int(nn)):
        if v[2+i]<0 or v[2+i]>50:return -1
        nums[i]=v[2+i];remaining+=v[2+i]
    var staged=InlineArray[UInt8,90120](fill=0);var pos=InlineArray[Int,1](fill=8);var count=InlineArray[Int,1](fill=0);var path=InlineArray[Int64,10](fill=0)
    subsets_visit(nums.unsafe_ptr(),Int(nn),target,0,0,remaining,path.unsafe_ptr(),0,staged.unsafe_ptr(),pos.unsafe_ptr(),count.unsafe_ptr())
    var head=InlineArray[UInt8,8](fill=0);var cv=UInt64(count[0])
    for b in range(8):head[b]=UInt8((cv>>UInt(b*8))&255)
    for b in range(8):staged[b]=head[b]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos[0]):return -2
    for i in range(pos[0]):out[i]=staged[i]
    return pos[0]
