from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stack_tracking_min_max")
fn stack_tracking_min_max(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let maxsz=v[0];let opsv=v[1]
    if maxsz<0 or maxsz>64 or opsv<0 or opsv>64:return -1
    var p=2
    for _ in range(Int(opsv)):
        if p>=Int(n):return -1
        let op=v[p];p+=1
        if op==1:
            if p>=Int(n) or v[p]< -2147483648 or v[p]>2147483647:return -1
            p+=1
        elif op<2 or op>5:return -1
    if p!=Int(n):return -1
    var vals=InlineArray[Int64,64](fill=0);var mins=InlineArray[Int64,64](fill=0);var maxs=InlineArray[Int64,64](fill=0);var records=InlineArray[Int64,192](fill=0);var top=0;var rc=0;p=2
    for _ in range(Int(opsv)):
        let op=v[p];p+=1;var tag:Int64=0;var result:Int64=0
        if op==1:
            let x=v[p];p+=1
            if top==Int(maxsz):records[3*rc]=1;records[3*rc+1]=4;records[3*rc+2]=1;rc+=1;break
            vals[top]=x;mins[top]=x if top==0 or x<mins[top-1] else mins[top-1];maxs[top]=x if top==0 or x>maxs[top-1] else maxs[top-1];top+=1;tag=1;result=1
        elif op==2:
            if top>0:top-=1;result=vals[top]
            else:tag=3
        elif op==3:
            if top>0:result=mins[top-1]
            else:tag=3
        elif op==4:
            if top>0:result=maxs[top-1]
            else:tag=3
        else:tag=1;result=1 if top>0 else 0
        records[3*rc]=op;records[3*rc+1]=tag;records[3*rc+2]=result;rc+=1
    let bytes=rc*24
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(3*rc):let bits=bitcast[UInt64](records[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
