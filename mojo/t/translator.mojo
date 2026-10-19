from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("translator")
fn translator(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>107 or a[0]<0 or a[0]>4 or a[1]<0 or a[1]>64:return -1
    let nk=Int(a[0]);let nt=Int(a[1]);var kl=InlineArray[Int,4]();var vl=InlineArray[Int,4]();var keys=InlineArray[Int,16]();var vals=InlineArray[Int,16]();var pos=2
    for k in range(nk):
        if pos+2>Int(n):return -1
        let klen=a[pos];let vlen=a[pos+1];pos+=2
        if klen<1 or klen>4 or vlen<0 or vlen>4 or pos+Int(klen+vlen)>Int(n):return -1
        kl[k]=Int(klen);vl[k]=Int(vlen)
        for j in range(Int(klen)):
            if a[pos+j]<32 or a[pos+j]>126:return -1
            keys[k*4+j]=Int(a[pos+j])
        pos+=Int(klen)
        for j in range(Int(vlen)):
            if a[pos+j]<32 or a[pos+j]>126:return -1
            vals[k*4+j]=Int(a[pos+j])
        pos+=Int(vlen)
        for old in range(k):
            if kl[old]==kl[k]:
                var same=True
                for j in range(kl[k]):
                    if keys[k*4+j]!=keys[old*4+j]:same=False
                if same:return -1
    if pos+nt!=Int(n):return -1
    var text=InlineArray[Int,64]()
    for j in range(nt):
        if a[pos+j]<32 or a[pos+j]>126:return -1
        text[j]=Int(a[pos+j])
    var out=InlineArray[UInt8,256]();var outn=0;var start=0
    while start<nt:
        var matched=False
        for cand in range(1,min(4,nt-start)+1):
            if matched:break
            for k in range(nk):
                if kl[k]!=cand:continue
                var same=True
                for j in range(cand):
                    if text[start+j]!=keys[k*4+j]:same=False
                if same:
                    for j in range(vl[k]):out[outn]=UInt8(vals[k*4+j]);outn+=1
                    start+=cand;matched=True;break
        if not matched:break
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    for j in range(outn):o[j]=out[j]
    return Int64(outn)
