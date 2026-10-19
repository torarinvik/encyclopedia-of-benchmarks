from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_next_greater_element")
fn kth_next_greater_element(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>8 or a[0]<1 or a[0]>7:return -1
    let k=Int(a[0]);let count=Int(n)-1
    for i in range(count):if a[i+1]< -15 or a[i+1]>15:return -1
    var found=0
    for i in range(count):
        var cur=i;var ok=True
        for _ in range(k):
            var j=cur+1
            while j<count and a[j+1]<=a[cur+1]:j+=1
            if j==count:ok=False;break
            cur=j
        if ok:found+=1
    return found
