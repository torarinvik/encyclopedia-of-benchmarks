from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("two_pointers_pair_count")
fn two_pointers_pair_count(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let target=a[0];let count=a[1]
    if target< -2000000 or target>2000000 or count<0 or count>256 or n!=c_size_t(count+2):return -1
    var v=InlineArray[Int64,256]()
    for i in range(Int(count)):
        if a[i+2]< -1000000 or a[i+2]>1000000:return -1
        v[i]=a[i+2]
        for j in range(i):if v[i]==v[j]:return -1
    for i in range(1,Int(count)):
        let x=v[i];var j=i
        while j>0 and v[j-1]>x:v[j]=v[j-1];j-=1
        v[j]=x
    var l=0;var r=Int(count)-1;var result:Int64=0
    while l<r:
        let s=v[l]+v[r]
        if s==target:result+=1;l+=1
        elif s<target:l+=1
        else:r-=1
    return result
