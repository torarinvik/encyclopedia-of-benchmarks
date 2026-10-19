from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn perms_mix(h:UInt32,b:UInt8)->UInt32:return (h^UInt32(b))*16777619
@export("permutations")
fn permutations(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>7 or v[0]<1 or v[0]>6 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var a=InlineArray[Int32,6](fill=0)
    for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1;a[i]=Int32(v[i+1]);if i>0 and a[i-1]>=a[i]:return -1
    var h:UInt32=2166136261
    while True:
        for i in range(count):let u=UInt32(a[i]);for b in range(4):h=perms_mix(h,UInt8((u>>(8*b))&255))
        h=perms_mix(h,255)
        var i=count-1;while i>0 and a[i-1]>=a[i]:i-=1
        if i==0:break
        var j=count-1;while a[j]<=a[i-1]:j-=1
        let t=a[i-1];a[i-1]=a[j];a[j]=t;var l=i;var r=count-1
        while l<r:let x=a[l];a[l]=a[r];a[r]=x;l+=1;r-=1
    return Int64(h)
