from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pso_sorted(a:InlineArray[Int64,8],n:Int)->Bool:
    for i in range(1,n):if a[i-1]>a[i]:return False
    return True
@export("permutation_sort")
fn permutation_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>8:return -1
    let count=Int(n);var a=InlineArray[Int64,8](fill=0);var c=InlineArray[Int64,8](fill=0)
    for i in range(count):a[i]=v[i]
    var checked:Int64=1;if pso_sorted(a,count):return checked
    var i=0
    while i<count:
        if c[i]<i:
            let j=0 if i%2==0 else Int(c[i]);let t=a[j];a[j]=a[i];a[i]=t;c[i]+=1;checked+=1
            if pso_sorted(a,count):return checked
            i=0
        else:c[i]=0;i+=1
    return -1
