from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tr_hash(text:InlineArray[UInt8,544],length:Int)->Int64:
    var h:UInt64=14695981039346656037
    for b in range(8):h=(h^((UInt64(length)>>(8*b))&255))*1099511628211
    for i in range(length):
        let cp=UInt32(text[i])
        for b in range(4):h=(h^((UInt64(cp)>>(8*b))&255))*1099511628211
    return Int64(h&9223372036854775807)
@export("transposition")
fn transposition(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>547:return -1
    let mode=a[0];let kl0=a[1]
    if (mode!=0 and mode!=1) or kl0<1 or kl0>32:return -1
    let kl=Int(kl0);let ti=2+kl
    if Int(n)<=ti or a[ti]<1 or a[ti]>512 or n!=c_size_t(ti+1+a[ti]):return -1
    var key=InlineArray[Int,32]();var sorted=InlineArray[Int,32]();var ranks=InlineArray[Int,32]();var text=InlineArray[UInt8,544]();var result=InlineArray[UInt8,544]()
    for i in range(kl):
        let x=a[2+i]
        if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
        key[i]=Int(if x<=90 else x-32);sorted[i]=key[i]
    for i in range(1,kl):
        let x=sorted[i];var j=i
        while j>0 and sorted[j-1]>x:sorted[j]=sorted[j-1];j-=1
        sorted[j]=x
    for i in range(kl):
        var first=0
        while first<kl and sorted[first]!=key[i]:first+=1
        var dup=0
        for j in range(i):
            if key[j]==key[i]:dup+=1
        ranks[i]=first+dup+1
    let tn=Int(a[ti])
    for i in range(tn):
        let x=a[ti+1+i]
        if x<32 or x>126:return -1
        text[i]=UInt8(x)
    if mode==0 and text[tn-1]==32:return -1
    let pad=if mode==0 then kl-tn%kl else (if tn%kl==0 then 0 else kl-tn%kl)
    let plen=tn+pad
    for i in range(tn,plen):text[i]=32
    var outn=0
    if mode==0:
        for start in range(0,plen,kl):
            var block=InlineArray[UInt8,32]()
            for off in range(kl):block[ranks[off]-1]=text[start+off]
            for off in range(kl):result[outn]=block[off];outn+=1
    else:
        for start in range(0,plen,kl):
            for off in range(kl):result[outn]=text[start+ranks[off]-1];outn+=1
        while outn>0 and result[outn-1]==32:outn-=1
    return tr_hash(result,outn)
