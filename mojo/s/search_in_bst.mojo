from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("search_in_bst")
fn search_in_bst(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>15003:return -1
    let count=a[0];let root=a[1];let target=a[2]
    if count<1 or count>5000 or n!=c_size_t(3+3*count) or root<0 or root>=count or target<1 or target>10000000:return -1
    for i in range(Int(count)):
        let b=3+3*i;let v=a[b];let l=a[b+1];let r=a[b+2]
        if v<1 or v>10000000 or l< -1 or r< -1 or l>=count or r>=count:return -1
    var cur=Int(root)
    while cur>=0:
        let b=3+3*cur;let v=a[b]
        if v==target:return Int64(cur)
        cur=Int(a[b+1] if target<v else a[b+2])
    return -1
