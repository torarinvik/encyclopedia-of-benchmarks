from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wss_select(inout v:InlineArray[Int32,4096],n:Int,target:Int)->Int32:
    var low=0;var high=n-1
    while low<high:
        var l=low;var r=high;let pivot=v[(l+r+1)/2]
        while l<=r:
            while l<=r and v[l]<pivot:l+=1
            while l<=r and v[r]>pivot:r-=1
            if l<=r:let t=v[l];v[l]=v[r];v[r]=t;l+=1;r-=1
        if target<=r:high=r
        elif target>=l:low=l
        else:break
    return v[target]
@export("wiggle_sort_strict")
fn wiggle_sort_strict(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let count=Int(n);var v=InlineArray[Int32,4096]()
    for i in range(count):if a[i]< -2147483648 or a[i]>2147483647:return -1;else:v[i]=Int32(a[i])
    if cap<c_size_t(count*4) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if count==0:return 0
    let median=wss_select(v,count,count/2);var medcount=0;var minimum=v[0]
    for i in range(count):if v[i]==median:medcount+=1;if v[i]<minimum:minimum=v[i]
    let maxmed=(count+1)/2
    if medcount>maxmed or (count%2==1 and medcount==maxmed and minimum!=median):return -1
    var i=0;var j=0;var k=count-1;let modulus=count+1-count%2
    while j<=k:
        let mj=(2*j+1)%modulus
        if v[mj]>median:
            let mi=(2*i+1)%modulus;let t=v[mj];v[mj]=v[mi];v[mi]=t;i+=1;j+=1
        elif v[mj]<median:
            let mk=(2*k+1)%modulus;let t=v[mj];v[mj]=v[mk];v[mk]=t;k-=1
        else:j+=1
    for z in range(count):let bits=bitcast[UInt32](v[z]);for b in range(4):o[z*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(count)
