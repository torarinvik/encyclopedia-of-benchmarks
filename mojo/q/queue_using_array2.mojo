from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("queue_using_array2")
fn queue_using_array2(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513:return -1
    let q=a[0]
    if q<0 or q>256 or n!=c_size_t(1+2*q):return -1
    for i in range(Int(q)):
        let op=a[1+2*i];let value=a[2+2*i]
        if op==1:
            if value< -1000000 or value>1000000:return -1
        elif (op==2 or op==3):
            if value!=0:return -1
        else:return -1
    var values=InlineArray[Int64,10]();var count=0;var h:Int64=0
    for i in range(Int(q)):
        let op=a[1+2*i];let value=a[2+2*i]
        if op==1:
            if count<10:values[count]=value;count+=1
        elif op==2 and count>0:
            for j in range(1,count):values[j-1]=values[j]
            count-=1
        h=(h*1000003+op)%1000000007;h=(h+0) % 1000000007
        h=(h*1000003+count)%1000000007
        for j in range(count):h=(h*1000003+values[j]+1000001)%1000000007
    return h
