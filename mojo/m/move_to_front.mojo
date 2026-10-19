from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("move_to_front")
fn move_to_front(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>164:return -1
    let mode=Int(v[0]);let al=Int(v[1]);let tl=Int(v[2]);if (mode!=0 and mode!=1) or al<0 or al>32 or tl<0 or tl>128 or Int(n)!=3+al+tl:return -1
    var a=InlineArray[Int64,32](fill=0);var seen=InlineArray[Int64,128](fill=0)
    for i in range(al):let c=v[3+i];if c<0 or c>127:return -1;for j in range(i):if a[j]==c:return -1;a[i]=c
    if mode==0 and tl>0 and al==0:return -1
    var result=InlineArray[UInt8,128](fill=0);var outlen=0
    for i in range(tl):
        let x=v[3+al+i]
        if mode==1 and al==0:continue
        if x<0 or x>127:return -1
        var pos=0
        if mode==0:
            while pos<al and a[pos]!=x:pos+=1
            if pos==al:return -1
            result[outlen]=UInt8(pos);outlen+=1
        else:
            if x<0 or x>=al:return -1
            pos=Int(x);result[outlen]=UInt8(a[pos]);outlen+=1
        let sym=if mode==0:x else:a[pos]
        while pos>0:a[pos]=a[pos-1];pos-=1
        if al>0:a[0]=sym
    if cap<c_size_t(outlen) or (outlen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(outlen):o[i]=result[i]
    return Int64(outlen)
