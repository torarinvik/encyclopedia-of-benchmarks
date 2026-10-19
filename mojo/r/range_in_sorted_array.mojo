from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ria_find(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,key:Int64,leftward:Bool)->Int64:
    var left:Int64=0;var right=Int64(n)-1
    while left<=right:
        let mid=left+(right-left)//2;let x=v[Int(mid)]
        if x>key:right=mid-1
        elif x<key:left=mid+1
        elif leftward:
            if mid==0 or v[Int(mid-1)]!=key:return mid
            right=mid-1
        else:
            if mid==Int64(n)-1 or v[Int(mid+1)]!=key:return mid
            left=mid+1
    return -1
fn ria_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x)
    for j in range(4):o[at+j]=UInt8((b>>(8*j))&255)
@export("range_in_sorted_array")
fn range_in_sorted_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>514 or v[0]<0 or v[0]>512 or n!=c_size_t(v[0]+2):return -1
    let count=Int(v[0]);let key=v[count+1]
    if key < -2147483648 or key>2147483647:return -1
    for i in range(count):
        if v[i+1] < -2147483648 or v[i+1]>2147483647 or (i>0 and v[i]>v[i+1]):return -1
    let first=ria_find(v+1,count,key,True);let last=ria_find(v+1,count,key,False)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    ria_put(o,0,Int32(first));ria_put(o,4,Int32(last));return 8
