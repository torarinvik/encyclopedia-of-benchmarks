from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime SUMS=4001
fn sumset_append(out:UnsafePointer[UInt8,MutAnyOrigin],pos:UnsafePointer[Int,MutAnyOrigin],x:Int):
    var value=x
    if value<0:out[pos[0]]=45;pos[0]+=1;value= -value
    var digits=InlineArray[UInt8,5](fill=0);var count=0
    while True:
        digits[count]=UInt8(value%10);count+=1;value/=10
        if value==0:break
    while count>0:count-=1;out[pos[0]]=UInt8(48)+digits[count];pos[0]+=1
    out[pos[0]]=10;pos[0]+=1
@export("sumset")
fn sumset(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let na=v[0];let nb=v[1]
    if na<0 or na>64 or nb<0 or nb>64 or n!=c_size_t(2+na+nb):return -1
    for i in range(Int(na+nb)):if v[2+i]< -1000 or v[2+i]>1000:return -1
    var present=InlineArray[UInt8,SUMS](fill=0)
    for i in range(Int(na)):
        for j in range(Int(nb)):present[Int(v[2+i]+v[2+Int(na)+j]+2000)]=1
    var bytes=0
    for i in range(SUMS):
        if present[i]!=0:
            var x=i-2000;var width=1
            if x<0:x= -x;width+=1
            while x>=10:x/=10;width+=1
            bytes+=width+1
    if bytes==0:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[UInt8,24006](fill=0);var pos=InlineArray[Int,1](fill=0)
    for i in range(SUMS):if present[i]!=0:sumset_append(staged.unsafe_ptr(),pos.unsafe_ptr(),i-2000)
    for i in range(bytes):out[i]=staged[i]
    return bytes
