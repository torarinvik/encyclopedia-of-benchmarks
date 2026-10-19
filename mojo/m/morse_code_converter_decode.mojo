from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mcd_get(i:Int)->Int64:
    let w=InlineArray[Int64,26](514,1031,1029,771,257,1037,769,1039,515,1032,770,1035,512,513,768,1033,1026,773,775,256,774,1038,772,1030,1028,1027)
    return w[i]
fn mcd_char(v:UnsafePointer[Int64,ImmutAnyOrigin],a:Int,b:Int)->UInt8:
    if a>=b:return 63
    var mask=0;for i in range(a,b):if v[i]==46:mask=(mask<<1)|1 elif v[i]==45:mask<<=1 else:return 63
    let size=b-a
    for i in range(26):let w=mcd_get(i);if Int((w>>8)&7)==size and Int(w&31)==mask:return UInt8(65+i)
    return 63
@export("morse_code_converter_decode")
fn morse_code_converter_decode(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()) or n>512:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var out=InlineArray[UInt8,512](fill=0);var w=0;let len=Int(n)
    if len==0:out[0]=63;w=1
    else:
        var end=len;while end>=3 and v[end-3]==32 and v[end-2]==124 and v[end-1]==32:end-=3
        if end>0:
            var start=0;var p=0
            while p<=end:
                if p==end or (p+2<end and v[p]==32 and v[p+1]==124 and v[p+2]==32):
                    var word_end=p
                    while word_end>start and v[word_end-1]==32:word_end-=1
                    if word_end==start:
                        if start==p:out[w]=63;w+=1
                    else:
                        var tok=start
                        for q in range(start,word_end+1):
                            if q==word_end or v[q]==32:out[w]=mcd_char(v,tok,q);w+=1;tok=q+1
                    if p<end:out[w]=32;w+=1;p+=3;start=p
                    else:break
                else:p+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(w):return -2
    for i in range(w):o[i]=out[i]
    return Int64(w)
