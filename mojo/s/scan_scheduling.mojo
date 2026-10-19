from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("scan_scheduling")
fn scan_scheduling(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>68:return -1
    let disk=a[0];let head=a[1];let dir=a[2];let cnt=a[3]
    if disk<1 or disk>256 or head<0 or head>=disk or (dir!=0 and dir!=1) or cnt<0 or cnt>64 or n!=c_size_t(cnt+4):return -1
    var left=InlineArray[Int32,64]();var right=InlineArray[Int32,64]();var nl=0;var nr=0
    for i in range(Int(cnt)):
        let x=a[i+4];if x<0 or x>=disk:return -1
        if x<head:left[nl]=Int32(x);nl+=1
        else:right[nr]=Int32(x);nr+=1
    for i in range(1,nl):let x=left[i];var j=i;while j>0 and left[j-1]>x:left[j]=left[j-1];j-=1;left[j]=x
    for i in range(1,nr):let x=right[i];var j=i;while j>0 and right[j-1]>x:right[j]=right[j-1];j-=1;right[j]=x
    var result=InlineArray[Int32,65]();var z=0
    if cnt>0:
        if dir==1:
            for i in range(nr):result[z]=right[i];z+=1
            result[z]=Int32(disk-1);z+=1
            for i in range(nl):result[z]=left[nl-1-i];z+=1
        else:
            for i in range(nl):result[z]=left[nl-1-i];z+=1
            result[z]=0;z+=1
            for i in range(nr):result[z]=right[i];z+=1
    let bytes=z*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(z):let b=bitcast[UInt32](result[i]);for j in range(4):o[i*4+j]=UInt8((b>>UInt(8*j))&255)
    return Int64(bytes)
