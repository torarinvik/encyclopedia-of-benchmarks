from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linked_deque")
fn linked_deque(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>20 or n%2!=0:return -1
    var q=InlineArray[Int64,40](fill=0);var h=16;var t=16;var result:Int64=0;var place:Int64=1
    for p in range(0,Int(n),2):
        let op=v[p];let a=v[p+1]
        if op<0 or op>6:return -1
        if op<2:
            if a < -15 or a>15:return -1
            if op==0:h-=1;q[h]=a
            else:q[t]=a;t+=1
            continue
        if a!=0:return -1
        var d:Int64=0
        if op==2:
            if h<t:d=q[h]+16;h+=1
        elif op==3:
            if h<t:t-=1;d=q[t]+16
        elif op==4:
            if h<t:d=q[h]+16
        elif op==5:
            if h<t:d=q[t-1]+16
        else:d=if h==t:1 else:2
        result+=d*place;place*=32
    return result
