from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sj_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("shortest_job_first")
fn shortest_job_first(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let count=a[0];if count<0 or count>32 or n!=c_size_t(1+2*count):return -1
    var rem=InlineArray[Int64,32]();var arr=InlineArray[Int64,32]();var burst=InlineArray[Int64,32]();var wait=InlineArray[Int64,32]()
    for i in range(Int(count)):
        arr[i]=a[i+1];burst[i]=a[1+Int(count)+i];rem[i]=burst[i]
        if arr[i]<0 or arr[i]>64 or burst[i]<1 or burst[i]>=999999999 or burst[i]>128:return -1
    let bytes=(1+2*Int(count))*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var complete=0;var time:Int64=0;var minrem:Int64=999999999;var short=0;var check=False
    while complete<Int(count):
        for j in range(Int(count)):if arr[j]<=time and rem[j]>0 and rem[j]<minrem:minrem=rem[j];short=j;check=True
        if not check:time+=1;continue
        rem[short]-=1;minrem=rem[short];if minrem==0:minrem=999999999
        if rem[short]==0:complete+=1;check=False;wait[short]=max(0,time+1-arr[short]-burst[short])
        time+=1
    sj_put(o,0,count)
    for i in range(Int(count)):sj_put(o,(1+i)*8,wait[i])
    for i in range(Int(count)):sj_put(o,(1+Int(count)+i)*8,burst[i]+wait[i])
    return Int64(bytes)
