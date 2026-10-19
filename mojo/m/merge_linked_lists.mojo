from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mll_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=UInt64(x)
    for b in range(8):out[pos+b]=UInt8((bits>>(8*b))&255)

@export("merge_linked_lists")
fn merge_linked_lists(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let a=v[0];let b=v[1]
    if a<0 or a>32 or b<0 or b>32 or Int(n)!=Int(a+b)+2:return -1
    let total=Int(a+b);var vals=InlineArray[Int64,64](fill=0);var next=InlineArray[Int64,64](fill=-1)
    for i in range(total):
        let x=if i<Int(a):v[2+i] else:v[2+i]
        if x < -2147483648 or x > 2147483647:return -1
        vals[i]=x
        if i<Int(a)-1 or (i>=Int(a) and i<Int(a+b)-1):next[i]=Int64(i+1)
    var h1:Int64=if a==0:-1 else:0
    var t1=h1;var t2:Int64=if b==0:-1 else:a;var holder2:Int64=-1
    while t1!=-1 and t2!=-1:
        let holder1=next[Int(t1)];next[Int(t1)]=t2
        if holder1!=-1:
            holder2=next[Int(t2)];next[Int(t2)]=holder1
        t1=holder1;t2=holder2
    var staged=InlineArray[Int64,64](fill=0);var count=0;var node=h1
    while node!=-1 and count<64:
        staged[count]=vals[Int(node)];count+=1;node=next[Int(node)]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    for i in range(count):mll_store(out,i*8,staged[i])
    return Int64(count*8)
