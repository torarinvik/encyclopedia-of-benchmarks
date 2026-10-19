from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("queue_using_array")
fn queue_using_array(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let q=a[0]
    if q<0 or q>512 or n!=c_size_t(1+2*q):return -1
    var data=InlineArray[Int64,10]();var front=0;var rear= -1;var size=0;var k:Int64=0;var result:Int64=0
    for i in range(Int(q)):
        let op=a[1+2*i];let value=a[2+2*i]
        if op==0:
            if value< -128 or value>127:return -1
            if rear<9:rear+=1;data[rear]=value;size+=1
        elif op==1:
            if value!=0:return -1
            var d:Int64=0
            if size>0:d=data[front];front+=1;size-=1
            if size==0:front=0;rear= -1
            k+=1;result+=k*(d+128)
        else:return -1
    return result
