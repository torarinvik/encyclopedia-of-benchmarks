from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXN=256
comptime MAXB=17
fn kr_less(v:InlineArray[Int64,MAXN],s:InlineArray[Int64,MAXB],b:InlineArray[Int64,MAXB],p:InlineArray[Int64,MAXB],i:Int,j:Int)->Bool:
    let vi=v[Int(s[Int(b[i])]+p[i])];let vj=v[Int(s[Int(b[j])]+p[j])]
    return vi<vj or (vi==vj and (b[i]<b[j] or (b[i]==b[j] and p[i]<p[j])))
fn kr_push(v:InlineArray[Int64,MAXN],s:InlineArray[Int64,MAXB],mut hb:InlineArray[Int64,MAXB],mut hp:InlineArray[Int64,MAXB],mut hn:Int,blk:Int,pos:Int):
    var i=hn;hn+=1
    hb[i]=blk;hp[i]=pos
    while i>0:
        let par=(i-1)//2
        if not kr_less(v,s,hb,hp,i,par):break
        let tb=hb[i];hb[i]=hb[par];hb[par]=tb;let tp=hp[i];hp[i]=hp[par];hp[par]=tp;i=par
fn kr_pop(v:InlineArray[Int64,MAXN],s:InlineArray[Int64,MAXB],mut hb:InlineArray[Int64,MAXB],mut hp:InlineArray[Int64,MAXB],mut hn:Int):
    hn-=1
    if hn==0:return
    let lb=hb[hn];let lp=hp[hn];var i=0
    while 2*i+1<hn:
        var c=2*i+1
        if c+1<hn and kr_less(v,s,hb,hp,c+1,c):c+=1
        let vc=v[Int(s[Int(b[Int(c)])]+hp[Int(c)])];let vl=v[Int(s[Int(lb)]+lp)]
        if vc>vl or (vc==vl and (hb[c]>lb or (hb[c]==lb and hp[c]>=lp))):break
        hb[i]=hb[c];hp[i]=hp[c];i=c
    hb[i]=lb;hp[i]=lp
@export("kirkpatrick_reisch_sort")
fn kirkpatrick_reisch_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or a[0]<0 or a[0]>256 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0]);var vals=InlineArray[Int64,MAXN]();for i in range(count):vals[i]=a[i+1]
    var starts=InlineArray[Int64,MAXB]();var lens=InlineArray[Int64,MAXB]();var blocks=0;var bs=1
    if count>1:while (bs+1)*(bs+1)<=count:bs+=1
    var start=0
    while start<count:
        let len=if count<=1 then count else min(bs,count-start)
        starts[blocks]=start;lens[blocks]=len;blocks+=1
        for i in range(1,len):
            let v=vals[start+i];var j=i
            while j>0 and vals[start+j-1]>v:vals[start+j]=vals[start+j-1];j-=1
            vals[start+j]=v
        start+=max(1,bs)
    var hb=InlineArray[Int64,MAXB]();var hp=InlineArray[Int64,MAXB]();var hn=0
    for b in range(blocks):kr_push(vals,starts,hb,hp,hn,b,0)
    var sorted=InlineArray[Int64,MAXN]();var outn=0
    while hn>0:
        let b=Int(hb[0]);let off=Int(hp[0]);sorted[outn]=vals[Int(starts[b])+off];outn+=1
        kr_pop(vals,starts,hb,hp,hn)
        if off+1<Int(lens[b]):kr_push(vals,starts,hb,hp,hn,b,off+1)
    let bytes=outn*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(outn):let bits=UInt64(sorted[i]);for j in range(8):o[i*8+j]=UInt8((bits>>(8*j))&255)
    return bytes
