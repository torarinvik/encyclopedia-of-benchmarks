from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mmw_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("maximum_minimum_window")
fn maximum_minimum_window(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>256 or n!=c_size_t(v[0]+1):return -2
    let count=Int(v[0]);for i in range(count):if v[i+1]<0 or v[i+1]>1000000:return -2
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -3
    var stack=InlineArray[Int,256](fill=0);var left=InlineArray[Int,256](fill=0);var right=InlineArray[Int,256](fill=0);var ans=InlineArray[Int64,257](fill=0);var top=0
    for i in range(count):
        while top>0 and v[stack[top-1]+1]>=v[i+1]:top-=1
        left[i]=stack[top-1] if top>0 else -1;stack[top]=i;top+=1
    top=0
    for rev in range(count):
        let i=count-1-rev
        while top>0 and v[stack[top-1]+1]>=v[i+1]:top-=1
        right[i]=stack[top-1] if top>0 else count;stack[top]=i;top+=1
    for i in range(count):
        let size=right[i]-left[i]-1
        if v[i+1]>ans[size]:ans[size]=v[i+1]
    for rev in range(count-1):
        let i=count-1-rev
        if ans[i-1]<ans[i]:ans[i-1]=ans[i]
    var staged=InlineArray[Int64,256](fill=0)
    for i in range(count):staged[i]=ans[i+1]
    for i in range(count):mmw_store(out,i*8,staged[i])
    return Int64(count)
