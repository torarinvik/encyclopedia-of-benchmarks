from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pmix(h:UInt32,b:UInt8)->UInt32:return (h^UInt32(b))*16777619
@export("permutate_string")
fn permutate_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>8 or v[0]<1 or v[0]>7 or Int(n)!=Int(v[0])+1:return -1
    let len=Int(v[0]);var a=InlineArray[UInt8,7](fill=0)
    for i in range(len):let x=v[i+1];if x<33 or x>126:return -1;a[i]=UInt8(x);for j in range(i):if a[j]==a[i]:return -1
    for i in range(1,len):let x=a[i];var j=i;while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1;a[j]=x
    var h:UInt32=2166136261
    while True:
        for i in range(len):h=pmix(h,a[i])
        h=pmix(h,0)
        var i=len-1;while i>0 and a[i-1]>=a[i]:i-=1
        if i==0:break
        var j=len-1;while a[j]<=a[i-1]:j-=1
        let t=a[i-1];a[i-1]=a[j];a[j]=t
        var l=i;var r=len-1
        while l<r:let z=a[l];a[l]=a[r];a[r]=z;l+=1;r-=1
    return Int64(h)
