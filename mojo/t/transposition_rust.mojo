from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tr_norm(src:InlineArray[UInt8,511],length:Int,inout dst:InlineArray[UInt8,511])->Int:
    var out=0
    for i in range(length):
        var c=src[i]
        if c>=97 and c<=122:c-=32
        if c>=65 and c<=90:dst[out]=c;out+=1
    return out
fn tr_colorder(key:InlineArray[UInt8,128],off:Int,klen:Int,inout order:InlineArray[Int,32]):
    for i in range(klen):order[i]=i
    for i in range(1,klen):
        let col=order[i];var pos=i
        while pos>0 and key[off+order[pos-1]]>key[off+col]:order[pos]=order[pos-1];pos-=1
        order[pos]=col
fn tr_hash(text:InlineArray[UInt8,511],length:Int)->Int64:
    var h:UInt64=14695981039346656037
    for b in range(8):h=(h^((UInt64(length)>>(8*b))&255))*1099511628211
    for i in range(length):
        var cp=UInt32(text[i])
        for _ in range(4):h=(h^UInt64(cp&255))*1099511628211;cp=cp>>8
    return Int64(h&9223372036854775807)
@export("transposition_rust")
fn transposition_rust(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>391:return -1
    let mode=a[0];let nk0=a[1]
    if (mode!=0 and mode!=1) or nk0<1 or nk0>4:return -1
    let nk=Int(nk0);var keys=InlineArray[UInt8,128]();var lens=InlineArray[Int,4]();var longest=0;var pos=2
    for k in range(nk):
        if pos>=Int(n) or a[pos]<1 or a[pos]>32:return -1
        let kl=Int(a[pos]);pos+=1
        if kl>Int(n)-pos:return -1
        for j in range(kl):
            let x=a[pos+j]
            if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
            keys[k*32+j]=UInt8(if x>=97 else x+32)
        lens[k]=kl;longest=max(longest,kl);pos+=kl
    if pos>=Int(n) or a[pos]<1 or a[pos]>256:return -1
    let msglen=Int(a[pos]);pos+=1
    if msglen!=Int(n)-pos:return -1
    var current=InlineArray[UInt8,511]();var filtered=InlineArray[UInt8,511]();var next=InlineArray[UInt8,511]();var clen=0
    for i in range(msglen):
        let x=a[pos+i]
        if x<0 or x>127:return -1
        var c=UInt8(x)
        if c>=97 and c<=122:c-=32
        if c>=65 and c<=90:current[clen]=c;clen+=1
    if clen<longest:return -1
    for round in range(nk):
        let ki=if mode==0 then round else nk-1-round
        let flen=tr_norm(current,clen,filtered);var order=InlineArray[Int,32]();tr_colorder(keys,ki*32,lens[ki],order)
        var nextlen=0
        if mode==0:
            var cols=InlineArray[UInt8,256]();var used=0
            for rank in range(lens[ki]):
                var at=order[rank]
                while at<flen:cols[used]=filtered[at];used+=1;at+=lens[ki]
            let group=(flen+lens[ki]-1)/lens[ki]
            for i in range(used):
                next[nextlen]=cols[i];nextlen+=1
                if (i+1)%group==0 and i+1<used:next[nextlen]=32;nextlen+=1
        else:
            var cols=InlineArray[UInt8,1024]();var lens2=InlineArray[Int,32]();let short=flen/lens[ki];let longer=flen%lens[ki];var cursor=0
            for rank in range(lens[ki]):
                let col=order[rank];let size=short+(1 if col<longer else 0);lens2[col]=size
                for row in range(size):cols[col*32+row]=filtered[cursor];cursor+=1
            let rows=short+(1 if longer>0 else 0)
            for row in range(rows):
                for col in range(lens[ki]):
                    if row<lens2[col]:next[nextlen]=cols[col*32+row];nextlen+=1
        for i in range(nextlen):current[i]=next[i]
        clen=nextlen
    return tr_hash(current,clen)
