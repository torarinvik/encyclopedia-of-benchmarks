from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pncounter")
fn pncounter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>69 or v[0]<1 or v[0]>16 or v[4]<0 or v[4]>64:return -1
    let nodes=Int(v[0]);let ops=Int(v[4])
    for c in range(3):if v[1+c]<0 or v[1+c]>=v[0]:return -1
    if n!=c_size_t(5+ops):return -1
    var p=InlineArray[Int64,48](fill=0);var neg=InlineArray[Int64,48](fill=0);var words=InlineArray[Int64,128](fill=0);var wc=0
    for j in range(ops):
        let op=v[5+j]
        if op<0 or op>20:return -1
        if op<6:
            let c=Int(op//2);let ix=c*16+Int(v[1+c])
            if op%2==0:p[ix]+=1
            else:neg[ix]+=1
            words[wc]=op;wc+=1
        elif op<9:
            let c=Int(op-6);var value=Int64(0)
            for nd in range(nodes):value+=p[c*16+nd]-neg[c*16+nd]
            words[wc]=op;words[wc+1]=value;wc+=2
        else:
            let pair=Int(op-9);var a=0;var b=0
            if pair==0:a=0;b=1
            elif pair==1:a=0;b=2
            elif pair==2:a=1;b=0
            elif pair==3:a=1;b=2
            elif pair==4:a=2;b=0
            else:a=2;b=1
            if op<15:
                for nd in range(nodes):
                    let x=a*16+nd;let y=b*16+nd
                    if p[x]<p[y]:p[x]=p[y]
                    if neg[x]<neg[y]:neg[x]=neg[y]
                words[wc]=op;wc+=1
            else:
                var result=Int64(1)
                for nd in range(nodes):
                    let x=a*16+nd;let y=b*16+nd
                    if p[x]>p[y] and neg[x]>neg[y]:result=0
                words[wc]=op;words[wc+1]=result;wc+=2
    let bytes=wc*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(wc):
        let bits=UInt64(words[i])
        for b in range(8):out[i*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
