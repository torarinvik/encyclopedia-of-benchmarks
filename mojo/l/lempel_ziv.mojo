from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

fn lz_key_find(keys:InlineArray[Int64,16900],lens:InlineArray[Int64,130],count:Int,q:InlineArray[Int64,130],ql:Int)->Int:
    for e in range(count):
        if lens[e]!=ql:continue
        var same=True
        for j in range(ql):
            if keys[e*130+j]!=q[j]:same=False;break
        if same:return e
    return count
fn lz_power_two(x:Int)->Bool:return x>0 and (x&(x-1))==0
fn lz_code(n:Int,mut out:InlineArray[Int64,8])->Int:
    var x=n;var tmp=InlineArray[Int64,8](fill=0);var len=0
    while x>0:
        if len>=8:return 0
        tmp[len]=x&1;len+=1;x>>=1
    for i in range(len):out[i]=tmp[len-1-i]
    return len

@export("compress_data")
fn lempel_ziv(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let bits=v[0]
    if bits<0 or bits>128 or n!=c_size_t(bits+1):return -1
    for i in range(Int(bits)):
        if v[i+1]!=48 and v[i+1]!=49:return -1
    var keys=InlineArray[Int64,16900](fill=0);var lens=InlineArray[Int64,130](fill=0);var codes=InlineArray[Int64,1040](fill=0);var clen=InlineArray[Int64,130](fill=0)
    lens[0]=1;lens[1]=1;keys[0]=0;keys[130]=1;clen[0]=1;clen[1]=1;codes[0]=0;codes[8]=1
    var count=2;var index=2;var current=InlineArray[Int64,130](fill=0);var cur=0;var encoded=InlineArray[UInt8,1032](fill=UInt8(0));var outlen=0
    for bi in range(Int(bits)):
        current[cur]=if v[bi+1]==48:0 else:1;cur+=1
        let match=lz_key_find(keys,lens,count,current,cur)
        if match==count:continue
        let code_len=Int(clen[match])
        for j in range(code_len):encoded[outlen]=UInt8(48+codes[match*8+j]);outlen+=1
        var matched=InlineArray[Int64,8](fill=0)
        for j in range(code_len):matched[j]=codes[match*8+j]
        # Remove the consumed dictionary entry, preserving the source's order.
        for e in range(match,count-1):
            lens[e]=lens[e+1];clen[e]=clen[e+1]
            for j in range(130):keys[e*130+j]=keys[(e+1)*130+j]
            for j in range(8):codes[e*8+j]=codes[(e+1)*8+j]
        count-=1
        var child=InlineArray[Int64,130](fill=0)
        for j in range(cur):child[j]=current[j]
        child[cur]=0
        var found=lz_key_find(keys,lens,count,child,cur+1)
        if found<count:
            clen[found]=Int64(code_len)
            for j in range(code_len):codes[found*8+j]=matched[j]
        else:
            if count>=130 or cur+1>129 or code_len>8:return -1
            lens[count]=Int64(cur+1);clen[count]=Int64(code_len)
            for j in range(cur+1):keys[count*130+j]=child[j]
            for j in range(code_len):codes[count*8+j]=matched[j]
            count+=1
        if lz_power_two(index):
            for e in range(count):
                if clen[e]>=8:return -1
                var j=Int(clen[e])-1
                while j>=0:codes[e*8+j+1]=codes[e*8+j];j-=1
                codes[e*8]=0;clen[e]+=1
        child=InlineArray[Int64,130](fill=0)
        for j in range(cur):child[j]=current[j]
        child[cur]=1
        var newcode=InlineArray[Int64,8](fill=0);let newlen=lz_code(index,newcode)
        if newlen==0:return -1
        found=lz_key_find(keys,lens,count,child,cur+1)
        if found<count:
            clen[found]=Int64(newlen)
            for j in range(newlen):codes[found*8+j]=newcode[j]
        else:
            if count>=130:return -1
            lens[count]=Int64(cur+1);clen[count]=Int64(newlen)
            for j in range(cur+1):keys[count*130+j]=child[j]
            for j in range(newlen):codes[count*8+j]=newcode[j]
            count+=1
        index+=1;cur=0
    if cur>0:
        var maxkey=0
        for e in range(count):maxkey=max(maxkey,Int(lens[e]))
        while True:
            let found=lz_key_find(keys,lens,count,current,cur)
            if found<count:
                for j in range(Int(clen[found])):encoded[outlen]=UInt8(48+codes[found*8+j]);outlen+=1
                break
            if cur>=maxkey or cur>=129:return -1
            current[cur]=0;cur+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    for i in range(outlen):out[i]=encoded[i]
    return Int64(outlen)
