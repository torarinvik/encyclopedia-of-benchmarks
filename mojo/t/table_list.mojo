from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tl_append(mut r:InlineArray[Int64,594],mut c:Int,x:Int64):
    r[c]=x;c+=1
@export("table_list")
fn table_list(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>98:return -1
    let ops=a[0]
    if ops<0 or ops>32 or n!=c_size_t(1+3*ops):return -1
    var items=InlineArray[Int64,64]();var head=32;var size=0;var records=InlineArray[Int64,594]();var rc=0;var cur=1
    for _ in range(Int(ops)):
        let op=a[cur];let x=a[cur+1];let y=a[cur+2];cur+=3
        if op<0 or op>11:return -1
        if op==0 or op==1:
            if x< -1000000 or x>1000000 or y!=0 or size>=32:return -1
            if op==0:head-=1;items[head]=x
            else:items[head+size]=x
            size+=1;tl_append(records,rc,op);tl_append(records,rc,0)
        elif op==2:
            if x!=0 or y!=0:return -1
            tl_append(records,rc,op)
            if size==0:tl_append(records,rc,0)
            else:tl_append(records,rc,1);tl_append(records,rc,items[head]);head+=1;size-=1
        elif op==3:
            if x!=0 or y!=0:return -1
            tl_append(records,rc,op)
            if size==0:tl_append(records,rc,0)
            else:size-=1;tl_append(records,rc,1);tl_append(records,rc,items[head+size])
        elif op==4 or op==5:
            if x!=0 or y!=0:return -1
            tl_append(records,rc,op)
            if size==0:tl_append(records,rc,0)
            else:tl_append(records,rc,1);tl_append(records,rc,items[head] if op==4 else items[head+size-1])
        elif op==6:
            if y!=0 or x<1 or x>size:return -1
            tl_append(records,rc,op);tl_append(records,rc,1);tl_append(records,rc,items[head+Int(x)-1])
        elif op==7:
            if x<1 or x>size or y< -1000000 or y>1000000:return -1
            items[head+Int(x)-1]=y;tl_append(records,rc,op);tl_append(records,rc,0)
        elif op==8:
            if x< -1 or x>33 or y!=0:return -1
            tl_append(records,rc,op);tl_append(records,rc,1);tl_append(records,rc,1 if x>=1 and x<=size else 0)
        elif op==9:
            if x!=0 or y!=0:return -1
            tl_append(records,rc,op);tl_append(records,rc,1);tl_append(records,rc,size)
        else:
            if x!=0 or y!=0:return -1
            tl_append(records,rc,op);tl_append(records,rc,size)
            for j in range(size):
                let logical=j+1 if op==10 else size-j
                tl_append(records,rc,logical);tl_append(records,rc,items[head+logical-1])
    tl_append(records,rc,12);tl_append(records,rc,size)
    for i in range(size):tl_append(records,rc,items[head+i])
    let bytes=rc*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rc):let bits=bitcast[UInt64](records[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
