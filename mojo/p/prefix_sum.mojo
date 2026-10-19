from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("prefix_sum")
fn prefix_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<0 or v[0]>2 or v[1]<0 or v[1]>256:return -1
    let op=Int(v[0]);let count=Int(v[1]);let extra=2 if op==1 else 1 if op==2 else 0
    if n!=c_size_t(2+count+extra) or (op==1 and count==0):return -1
    for i in range(count):if v[2+i]< -2147483648 or v[2+i]>2147483647:return -1
    if op==1 and (v[2+count]<0 or v[3+count]<v[2+count] or v[3+count]>=count):return -1
    if op==2 and (v[2+count]< -1000000000000 or v[2+count]>1000000000000):return -1
    var pref=InlineArray[Int64,257](fill=0)
    for i in range(count):pref[i+1]=pref[i]+v[2+i]
    let words=count if op==0 else 1
    if cap<c_size_t(words*8) or (words>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if op==0:
        for i in range(count):
            let bits=UInt64(pref[i+1])
            for b in range(8):out[i*8+b]=UInt8((bits>>(8*b))&255)
        return Int64(count)
    var result=Int64(0)
    if op==1:result=pref[Int(v[3+count])+1]-pref[Int(v[2+count])]
    else:
        var found=False
        for end in range(1,count+1):for start in range(end):if pref[end]-pref[start]==v[2+count]:found=True
        result=1 if found else 0
    let bits=UInt64(result)
    for b in range(8):out[b]=UInt8((bits>>(8*b))&255)
    return 1
