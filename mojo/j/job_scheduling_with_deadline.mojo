from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("job_scheduling_with_deadline")
fn job_scheduling_with_deadline(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513 or v[0]<0 or v[0]>128 or n!=c_size_t(1+4*v[0]):return -1
    let count=Int(v[0]);var ids=InlineArray[Int64,128](fill=0);var ar=InlineArray[Int64,128](fill=0);var dl=InlineArray[Int64,128](fill=0);var pr=InlineArray[Int64,128](fill=0);var maxd:Int64=0
    for i in range(count):
        let p=1+4*i;ids[i]=v[p];ar[i]=v[p+1];dl[i]=v[p+2];pr[i]=v[p+3]
        if ids[i]<0 or ids[i]>2147483647 or ar[i]<1 or ar[i]>32 or dl[i]<1 or dl[i]>32 or pr[i]< -1000000 or pr[i]>1000000:return -1
        for j in range(i):if ids[i]==ids[j]:return -1
        if dl[i]>maxd:maxd=dl[i]
    for i in range(1,count):
        let ki=ids[i];let ka=ar[i];let kd=dl[i];let kp=pr[i];var p=i
        while p>0 and pr[p-1]<kp:ids[p]=ids[p-1];ar[p]=ar[p-1];dl[p]=dl[p-1];pr[p]=pr[p-1];p-=1
        ids[p]=ki;ar[p]=ka;dl[p]=kd;pr[p]=kp
    var slots=InlineArray[Bool,32](fill=False);var scheduled:Int64=0;var total:Int64=0
    for i in range(count):
        if ar[i]<=dl[i]:
            var s=dl[i]-1 if dl[i]-1<maxd-1 else maxd-1
            while s>=ar[i]-1:
                if not slots[Int(s)]:slots[Int(s)]=True;scheduled+=1;total+=pr[i];break
                s-=1
    var low=total;if low<0:low+=4294967296
    return scheduled*4294967296+low
