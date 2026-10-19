from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime TMS_MASK=0x7fffffffffffffff
fn tms_byte(inout h:UInt64,b:UInt8):h=((h^UInt64(b))*1099511628211)&TMS_MASK
fn tms_u16(inout h:UInt64,v:Int):
    for s in range(2):tms_byte(h,UInt8((v>> (s*8))&255))
fn tms_u32(inout h:UInt64,v:Int):
    for s in range(4):tms_byte(h,UInt8((v>> (s*8))&255))
fn tms_less(words:InlineArray[InlineArray[UInt8,32],32],lens:InlineArray[Int32,32],a:Int,b:Int)->Bool:
    let m=min(Int(lens[a]),Int(lens[b]))
    for i in range(m):
        if words[a][i]!=words[b][i]:return words[a][i]<words[b][i]
    return lens[a]<lens[b]
@export("trie_multiple_search")
fn trie_multiple_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>2178:return -1
    if n>2177 or a[0]<0 or a[0]>64:return -1
    let opcount=Int(a[0]);var words=InlineArray[InlineArray[UInt8,32],32]();var lens=InlineArray[Int32,32]();var freq=InlineArray[Int32,32]();var wc=0
    var h:UInt64=14695981039346656037;tms_u16(h,opcount)
    var pos=1
    for _ in range(opcount):
        if pos+2>Int(n):return -1
        let op=a[pos];let wl=a[pos+1];pos+=2
        if op<0 or op>3 or wl<0 or wl>32 or (op==0 and wl==0) or pos+Int(wl)>Int(n):return -1
        var folded=InlineArray[UInt8,32]();var raw=InlineArray[UInt8,32]()
        for j in range(Int(wl)):
            let c=a[pos+j]
            if c>=65 and c<=90:raw[j]=UInt8(c);folded[j]=UInt8(c+32)
            elif c>=97 and c<=122:raw[j]=UInt8(c);folded[j]=UInt8(c)
            else:return -1
        pos+=Int(wl);tms_byte(h,UInt8(op))
        var exact= -1
        for wi in range(wc):
            if lens[wi]==wl:
                var same=true
                for j in range(Int(wl)):if words[wi][j]!=folded[j]:same=false
                if same:exact=wi
        if op==0:
            if exact<0:
                if wc>=32:return -1
                words[wc]=folded;lens[wc]=Int32(wl);wc+=1
            continue
        if op==1:
            let present=exact>=0
            if present:freq[exact]+=1
            tms_byte(h,UInt8(1 if present else 0));continue
        var matched=0
        for k in range(1,Int(wl)+1):
            var has=false
            for wi in range(wc):
                if lens[wi]>=k:
                    var prefix=true
                    for j in range(k):if words[wi][j]!=folded[j]:prefix=false
                    if prefix:has=true
            if has:matched=k
        var sug=InlineArray[Int32,32]();var sc=0
        for wi in range(wc):
            if Int(lens[wi])>matched:
                var prefix=true
                for j in range(matched):if words[wi][j]!=folded[j]:prefix=false
                if prefix:sug[sc]=Int32(wi);sc+=1
        if exact>=0:freq[exact]+=1
        for i in range(1,sc):
            let cur=Int(sug[i]);var j=i
            while j>0:
                let prev=Int(sug[j-1]);var before=false
                if op==2:before=tms_less(words,lens,cur,prev)
                else:before=freq[cur]>freq[prev] or (freq[cur]==freq[prev] and tms_less(words,lens,prev,cur))
                if not before:break
                sug[j]=sug[j-1];j-=1
            sug[j]=Int32(cur)
        let lim=if op==2 then sc else min(sc,3)
        tms_u16(h,lim+(1 if exact>=0 else 0))
        if exact>=0:
            tms_byte(h,UInt8(wl))
            for j in range(Int(wl)):tms_byte(h,raw[j])
        for j in range(lim):
            let wi=Int(sug[j]);tms_byte(h,UInt8(lens[wi]))
            for k in range(Int(lens[wi])):tms_byte(h,words[wi][k])
    if pos!=Int(n):return -1
    tms_u16(h,wc)
    var order=InlineArray[Int32,32]()
    for i in range(wc):order[i]=Int32(i)
    for i in range(1,wc):
        let cur=Int(order[i]);var j=i
        while j>0 and tms_less(words,lens,cur,Int(order[j-1])):order[j]=order[j-1];j-=1
        order[j]=Int32(cur)
    for i in range(wc):
        let wi=Int(order[i]);tms_byte(h,UInt8(lens[wi]))
        for j in range(Int(lens[wi])):tms_byte(h,words[wi][j])
        tms_u32(h,Int(freq[wi]))
    return Int64(h)
