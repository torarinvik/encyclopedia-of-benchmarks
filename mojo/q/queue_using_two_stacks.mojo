from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("queue_using_two_stacks")
fn queue_using_two_stacks(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or n%2!=0 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let ops=Int(n/2);var ins=InlineArray[Int64,256]();var outs=InlineArray[Int64,256]();var ic=0;var oc=0;var checksum:Int64=0
    for opi in range(ops):
        let op=a[2*opi];let value=a[2*opi+1];var observed:Int64=0;var returns=True
        if op==0:
            if value< -1000000 or value>1000000 or ic+oc>=256:return -1
            ins[ic]=value;ic+=1;returns=False
        elif op==1 or op==2:
            if value!=0:return -1
            if oc==0:
                while ic>0:ic-=1;outs[oc]=ins[ic];oc+=1
            if oc==0:return -1
            if op==1:oc-=1;observed=outs[oc]
            else:observed=outs[oc-1]
        elif op==3:
            if value!=0:return -1
            observed=1 if ic+oc==0 else 0
        elif op==4:
            if value!=0:return -1
            observed=ic+oc
        else:return -1
        if returns:checksum+=(Int64(opi)+1)*(observed+1000000)
    for i in range(oc):checksum+=(Int64(ops)+Int64(i)+1)*(outs[oc-i-1]+1000000)
    for i in range(ic):checksum+=(Int64(ops+oc+i)+1)*(ins[i]+1000000)
    return checksum
