from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("grow_only_set")
fn grow_only_set(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>25 or v[0]<0 or v[0]>12 or n!=c_size_t(1+2*v[0]):return -1
    var left=UInt32(0);var right=UInt32(0);var answers=UInt64(0);var query=0
    for i in range(Int(v[0])):
        let op=Int(v[1+2*i]);let arg=v[2+2*i]
        if op<0 or op>7:return -1
        if op<=3:
            if arg<0 or arg>15:return -1
        elif arg!=0:return -1
        let bit=UInt32(1)<<UInt32(arg) if op<=3 else UInt32(0)
        if op==0:left|=bit
        elif op==1:right|=bit
        elif op==2 or op==3:
            let set=left if op==2 else right
            if (set&bit)!=0:answers|=UInt64(1)<<UInt64(query)
            query+=1
        elif op==4:
            if (left&right)==left:answers|=UInt64(1)<<UInt64(query)
            query+=1
        elif op==5:
            if (left&right)==right:answers|=UInt64(1)<<UInt64(query)
            query+=1
        elif op==6:left|=right
        else:right|=left
    return bitcast[Int64](answers|(UInt64(left)<<12)|(UInt64(right)<<28)|(UInt64(query)<<44))
