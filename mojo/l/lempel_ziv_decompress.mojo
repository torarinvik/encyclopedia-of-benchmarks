from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

fn lzd_find(keys:InlineArray[Int64,2210],lens:InlineArray[Int64,130],count:Int,q:InlineArray[Int64,130],ql:Int)->Int:
    for e in range(count):
        if lens[e]!=ql:continue
        var same=True
        for j in range(ql):
            if keys[e*17+j]!=q[j]:same=False;break
        if same:return e
    return count
fn lzd_power_two(x:Int)->Bool:return x>0 and (x&(x-1))==0
fn lzd_binary(n:Int,mut out:InlineArray[Int64,16])->Int:
    var x=n;var tmp=InlineArray[Int64,16](fill=0);var len=0
    while x>0:
        if len>=16:return 0
        tmp[len]=x&1;len+=1;x>>=1
    for i in range(len):out[i]=tmp[len-1-i]
    return len

@export("decompress_data")
fn lempel_ziv_decompress(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let bits=v[0]
    if bits<0 or bits>128 or n!=c_size_t(bits+1):return -1
    for i in range(Int(bits)):
        if v[i+1]!=48 and v[i+1]!=49:return -1
    var keys=InlineArray[Int64,2210](fill=0);var klen=InlineArray[Int64,130](fill=0);var vals=InlineArray[Int64,16900](fill=0);var vlen=InlineArray[Int64,130](fill=0)
    klen[0]=1;klen[1]=1;keys[0]=0;keys[17]=1;vlen[0]=1;vlen[1]=1;vals[0]=0;vals[130]=1
    var count=2;var index=2;var current=InlineArray[Int64,130](fill=0);var cur=0;var decoded=InlineArray[UInt8,8256](fill=UInt8(0));var olen=0
    for bi in range(Int(bits)):
        current[cur]=if v[bi+1]==48:0 else:1;cur+=1
        let m=lzd_find(keys,klen,count,current,cur)
        if m==count:continue
        let ml=Int(vlen[m]);var last=InlineArray[Int64,130](fill=0)
        for j in range(ml):last[j]=vals[m*130+j];decoded[olen]=UInt8(48+last[j]);olen+=1
        # The matched value becomes its previous value followed by zero.
        vlen[m]=Int64(ml+1)
        for j in range(ml):vals[m*130+j]=last[j]
        vals[m*130+ml]=0
        if lzd_power_two(index):
            for e in range(count):
                if klen[e]>=16:return -1
                var j=Int(klen[e])-1
                while j>=0:keys[e*17+j+1]=keys[e*17+j];j-=1
                keys[e*17]=0;klen[e]+=1
        var key=InlineArray[Int64,130](fill=0);let kl=lzd_binary(index,key)
        if kl==0:return -1
        let existing=lzd_find(keys,klen,count,key,kl)
        if existing==count:
            if count>=130:return -1
            klen[count]=Int64(kl)
            for j in range(kl):keys[count*17+j]=key[j]
            vlen[count]=Int64(ml+1)
            for j in range(ml):vals[count*130+j]=last[j]
            vals[count*130+ml]=1;count+=1
        else:
            vlen[existing]=Int64(ml+1)
            for j in range(ml):vals[existing*130+j]=last[j]
            vals[existing*130+ml]=1
        index+=1;cur=0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(olen):return -2
    for i in range(olen):out[i]=decoded[i]
    return Int64(olen)
