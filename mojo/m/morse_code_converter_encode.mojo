from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mce_get(i:Int)->Int64:
    let w=InlineArray[Int64,26](514,1031,1029,771,257,1037,769,1039,515,1032,770,1035,512,513,768,1033,1026,773,775,256,774,1038,772,1030,1028,1027)
    return w[i]
fn mce_ix(x:Int64)->Int:
    if x>=65 and x<=90:return Int(x-65)
    if x>=97 and x<=122:return Int(x-97)
    return -1
@export("morse_code_converter_encode")
fn morse_code_converter_encode(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()) or n>512:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var end=Int(n);while end>0 and v[end-1]==32:end-=1
    var scratch=InlineArray[UInt8,2560](fill=0);var w=0;var start=0
    if end>0:
        for pos in range(end+1):
            if pos==end or v[pos]==32:
                for j in range(start,pos):
                    let ix=mce_ix(v[j])
                    if ix>=0:
                        let code=mce_get(ix);let size=Int((code>>8)&7);let mask=Int(code&31)
                        for c in range(size):scratch[w]=if ((mask>>(size-c-1))&1)!=0:46 else:45;w+=1
                    scratch[w]=32;w+=1
                if pos<end:scratch[w]=124;scratch[w+1]=32;w+=2
                start=pos+1
    while w>0 and scratch[w-1]==32:w-=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(w):return -2
    for i in range(w):o[i]=scratch[i]
    return Int64(w)
