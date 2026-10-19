from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("timeline")
fn timeline(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>131 or a[0]<0 or a[0]>16:return -1
    let initial=Int(a[0]);let ci=1+2*initial
    if ci>=Int(n) or a[ci]<0 or a[ci]>32:return -1
    let commands=Int(a[ci])
    if Int(n)!=2+2*initial+3*commands:return -1
    var et=InlineArray[Int64,48]();var ev=InlineArray[Int64,48]();var count=initial
    for i in range(initial):
        let t=a[1+2*i];let v=a[2+2*i]
        if t<0 or t>1000000 or v< -32 or v>32:return -1
        et[i]=t;ev[i]=v
    for i in range(1,initial):
        let t=et[i];let v=ev[i];var j=i
        while j>0 and et[j-1]>t:et[j]=et[j-1];ev[j]=ev[j-1];j-=1
        et[j]=t;ev[j]=v
    var ops=InlineArray[Int64,32]();var aa=InlineArray[Int64,32]();var bb=InlineArray[Int64,32]()
    var pos=ci+1
    for i in range(commands):
        let op=a[pos];let x=a[pos+1];let y=a[pos+2]
        if op<0 or op>14:return -1
        if op<=2:
            if x<0 or x>1000000 or y< -32 or y>32:return -1
        elif op==3 or op==4 or op==5 or op==6 or op==8:
            if x<0 or x>1000000 or y!=0:return -1
        elif op==7 or op==9:
            if x< -32 or x>32 or y!=0:return -1
        elif x!=0 or y!=0:return -1
        ops[i]=op;aa[i]=x;bb[i]=y;pos+=3
    var out=InlineArray[Int64,691]();var words=0
    for cmd in range(commands):
        let op=ops[cmd];let x=aa[cmd];let y=bb[cmd];let rec=words
        out[words]=op;words+=1;out[words]=0;words+=1
        if op==0:et[count]=x;ev[count]=y;count+=1
        elif op==1:
            var found=False
            for i in range(count):
                if et[i]==x and ev[i]==y:found=True
            out[words]=1 if found else 0;words+=1
        elif op==2:
            var found=-1
            for i in range(count):
                if found<0 and et[i]==x and ev[i]==y:found=i
            if found>=0:
                for i in range(found+1,count):et[i-1]=et[i];ev[i-1]=ev[i]
                count-=1;out[words]=1
            else:out[words]=0
            words+=1
        elif op==3:
            for i in range(count):
                if et[i]==x:out[words]=ev[i];words+=1
        elif op==4 or op==5 or op==10 or op==12:
            var unique=InlineArray[Int64,48]();var un=0
            for i in range(count):
                var seen=False
                for j in range(i):
                    if et[j]==et[i]:seen=True
                if not seen and (op==10 or op==12 or (op==4 and et[i]<x) or (op==5 and et[i]>x)):
                    unique[un]=et[i];un+=1
            if op==4 or op==5:
                for i in range(1,un):
                    let z=unique[i];var j=i
                    while j>0 and unique[j-1]>z:unique[j]=unique[j-1];j-=1
                    unique[j]=z
            if op==12:out[words]=Int64(un);words+=1
            else:
                for i in range(un):out[words]=unique[i];words+=1
        elif op==6 or op==7:
            var existed=False;var wr=0
            for i in range(count):
                let matches=(et[i]==x) if op==6 else (ev[i]==x)
                if matches:existed=True
                else:et[wr]=et[i];ev[wr]=ev[i];wr+=1
            count=wr;out[words]=1 if existed else 0;words+=1
        elif op==8 or op==9:
            var found=False
            for i in range(count):
                if op==8 and et[i]==x:found=True
                elif op==9 and ev[i]==x:found=True
            out[words]=1 if found else 0;words+=1
        elif op==11:
            for i in range(count):out[words]=ev[i];words+=1
        elif op==13:out[words]=Int64(count);words+=1
        else:count=0
        out[rec+1]=Int64(words-rec-2)
    out[words]=-1;words+=1;out[words]=Int64(count);words+=1
    for i in range(count):out[words]=et[i];out[words+1]=ev[i];words+=2
    let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(words):
        let bits=UInt64(out[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
