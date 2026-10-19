from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn permute_next(mut a:InlineArray[UInt8,7],len:Int)->Bool:
    if len<2:return False
    var pivot=len-1;while pivot>0 and a[pivot-1]>=a[pivot]:pivot-=1
    if pivot==0:return False
    var successor=len-1;while a[successor]<=a[pivot-1]:successor-=1
    let t=a[pivot-1];a[pivot-1]=a[successor];a[successor]=t;var l=pivot;var r=len-1
    while l<r:let x=a[l];a[l]=a[r];a[r]=x;l+=1;r-=1
    return True
@export("permute_string")
fn permute_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>9 or v[0]<0 or v[0]>7 or Int(n)!=Int(v[0])+1:return -1
    let len=Int(v[0]);var a=InlineArray[UInt8,7](fill=0);var freq=InlineArray[Int64,128](fill=0)
    for i in range(len):let x=v[i+1];if x<0 or x>127:return -1;a[i]=UInt8(x);freq[Int(x)]+=1
    for i in range(1,len):let x=a[i];var j=i;while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1;a[j]=x
    var perms=if len==0:0 else:1
    if len>0:for i in range(2,len+1):perms*=i
    if len>0:for i in range(128):for f in range(Int(freq[i])):perms/=Int(f+1)
    let bytes=perms*len
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for row in range(perms):
        for col in range(len):o[row*len+col]=a[col]
        if row+1<perms:permute_next(mut a,len)
    return Int64(bytes)
