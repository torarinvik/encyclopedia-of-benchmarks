from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("permutation_unique_string")
fn permutation_unique_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>7 or v[0]<0 or v[0]>5 or Int(n)!=Int(v[0])+1:return -1
    let len=Int(v[0]);var a=InlineArray[UInt8,5](fill=0)
    for i in range(len):if v[i+1]<32 or v[i+1]>126:return -1;a[i]=UInt8(v[i+1])
    for i in range(1,len):let x=a[i];var j=i;while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1;a[j]=x
    var out=InlineArray[UInt8,601](fill=0);var count=0
    while True:
        for i in range(len):out[1+count*len+i]=a[i]
        count+=1;if len<2:break
        var pivot=len-1;while pivot>0 and a[pivot-1]>=a[pivot]:pivot-=1
        if pivot==0:break
        var successor=len-1;while a[successor]<=a[pivot-1]:successor-=1
        let t=a[pivot-1];a[pivot-1]=a[successor];a[successor]=t;var l=pivot;var r=len-1
        while l<r:let z=a[l];a[l]=a[r];a[r]=z;l+=1;r-=1
    out[0]=UInt8(count);let bytes=1+count*len
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bytes):o[i]=out[i]
    return Int64(bytes)
