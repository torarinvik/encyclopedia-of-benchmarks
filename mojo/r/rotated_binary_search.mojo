from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rotated_binary_search")
fn rotated_binary_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -2
    let countv=v[0];if countv<0 or countv>256 or Int(n)!=Int(countv)+2:return -2
    let size=Int(countv);if size==0:return -1
    let key=v[size+1];if key< -2147483648 or key>2147483647:return -2
    var drops=0
    for i in range(size):
        if v[i+1]< -2147483648 or v[i+1]>2147483647:return -2
        if i>0 and v[i]>v[i+1]:drops+=1
    if drops>1 or (drops==1 and v[size]>v[1]):return -2
    var left=0;var right=size-1
    while left<=right:
        let midx=left+(right-left)/2;let mid=v[midx+1]
        if key==mid:return Int64(midx)
        if v[left+1]==mid and mid==v[right+1]:
            left+=1;if right==0:break;right-=1;continue
        if v[left+1]<=mid:
            if v[left+1]<=key and key<mid:if midx==0:break;right=midx-1
            else:left=midx+1
        elif mid<key and key<=v[right+1]:left=midx+1
        else:if midx==0:break;right=midx-1
    return -1
