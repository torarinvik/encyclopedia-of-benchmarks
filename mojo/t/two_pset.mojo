from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("two_pset")
fn two_pset(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let q=a[0]
    if q<0 or q>256 or n!=c_size_t(1+4*q):return -1
    var add=InlineArray[Bool,128]();var rem=InlineArray[Bool,128]()
    var h:Int64=0;var p=1
    for _ in range(Int(q)):
        let op=a[p];let sid=a[p+1];let value=a[p+2];let other=a[p+3];p+=4
        if op<0 or op>4 or sid<0 or sid>1 or other<0 or other>1:return -1
        if (op<=2 and (value<0 or value>63 or other!=0)) or (op>=3 and value!=0):return -1
        let base=Int(sid)*64
        var result:Int64=0
        if op==0:add[base+Int(value)]=True
        elif op==1:
            let ix=base+Int(value)
            if add[ix] and not rem[ix]:rem[ix]=True
        elif op==2:result=1 if add[base+Int(value)] and not rem[base+Int(value)] else 0
        elif op==3:
            result=1
            for e in range(64):
                let x=base+e;let y=Int(other)*64+e
                if (add[x] and not add[y]) or (rem[x] and not rem[y]):result=0
        else:
            for e in range(64):
                let x=base+e;let y=Int(other)*64+e
                add[x]=add[x] or add[y];rem[x]=rem[x] or rem[y]
        h=(h*1000003+op)%1000000007;h=(h*1000003+result)%1000000007
    for group in range(4):
        for e in range(64):
            var bit=false
            if group==0:bit=add[e]
            elif group==1:bit=rem[e]
            elif group==2:bit=add[64+e]
            else:bit=rem[64+e]
            h=(h*1000003+(1 if bit else 0))%1000000007
    return h
