from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("range_sum_bst")
fn range_sum_bst(v:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,rootarg:Int64,low:Int64,high:Int64) abi("C")->Int64:
    if count>1023 or low<1 or high>100000 or low>high:return -1
    let size=Int(count)
    if size==0:return if rootarg== -1:0 else: -1
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or rootarg<0 or rootarg>=Int64(size):return -1
    var parents=InlineArray[Int64,1023](fill=0)
    for i in range(size):
        let value=v[3*i];let left=v[3*i+1];let right=v[3*i+2]
        if value<1 or value>100000 or left< -1 or right< -1 or left>=Int64(size) or right>=Int64(size):return -1
        if left>=0:parents[Int(left)]+=1;if parents[Int(left)]>1:return -1
        if right>=0:parents[Int(right)]+=1;if parents[Int(right)]>1:return -1
    if parents[Int(rootarg)]!=0:return -1
    for i in range(size):if i!=Int(rootarg) and parents[i]!=1:return -1
    var sn=InlineArray[Int64,1023](fill=0);var sl=InlineArray[Int64,1023](fill=0);var sh=InlineArray[Int64,1023](fill=0);var seen=InlineArray[Int64,1023](fill=0)
    var top=1;var visited=0;sn[0]=rootarg;sl[0]=0;sh[0]=100001;var total:Int64=0
    while top>0:
        top-=1;let ix=Int(sn[top]);let lower=sl[top];let upper=sh[top]
        if seen[ix]!=0:return -1
        seen[ix]=1;visited+=1;let value=v[3*ix];let left=v[3*ix+1];let right=v[3*ix+2]
        if value<=lower or value>=upper:return -1
        if low<=value and value<=high:total+=value
        if right>=0:sn[top]=right;sl[top]=value;sh[top]=upper;top+=1
        if left>=0:sn[top]=left;sl[top]=lower;sh[top]=value;top+=1
    return if visited==size:total else: -1
