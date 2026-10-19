from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sc_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let t=a%b;a=b;b=t
    return a
fn sc_push(v:Int64,items:UnsafePointer[Int64,MutAnyOrigin],agg:UnsafePointer[Int64,MutAnyOrigin],len0:Int)->Int:
    items[len0]=v;agg[len0]=v if len0==0 else sc_gcd(agg[len0-1],v);return len0+1
fn sc_put(o:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,v:Int64):
    let bits=UInt64(v);for b in range(8):o[pos+b]=UInt8((bits>>(8*b))&255)
@export("shortest_coprime_segment")
fn shortest_coprime_segment(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>128 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<1 or a[i]>1000:return -1
    var front=InlineArray[Int64,128]();var fg=InlineArray[Int64,128]();var back=InlineArray[Int64,128]();var bg=InlineArray[Int64,128]()
    var fl=0;var bl=0;var left=0;var bestlen=Int(n)+1;var beststart=0
    for right in range(Int(n)):
        bl=sc_push(a[right],back.unsafe_ptr(),bg.unsafe_ptr(),bl)
        var g=sc_gcd(fg[fl-1] if fl>0 else 0,bg[bl-1] if bl>0 else 0)
        while g==1:
            let current=right-left+1
            if current<bestlen:bestlen=current;beststart=left
            if fl==0:
                while bl>0:
                    bl-=1;fl=sc_push(back[bl],front.unsafe_ptr(),fg.unsafe_ptr(),fl)
            fl-=1;left+=1
            g=sc_gcd(fg[fl-1] if fl>0 else 0,bg[bl-1] if bl>0 else 0)
    if bestlen>Int(n):return 0
    let bytes=bestlen*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bestlen):sc_put(o,i*8,a[beststart+i])
    return bytes
