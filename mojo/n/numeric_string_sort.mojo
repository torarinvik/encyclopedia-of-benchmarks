from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn nss_less(flat:InlineArray[UInt8,2048],starts:InlineArray[Int,64],lens:InlineArray[Int,64],norms:InlineArray[Int,64],i:Int,j:Int)->Bool:
    if norms[i]!=norms[j]:return norms[i]<norms[j]
    for k in range(norms[i]):
        let x=flat[starts[i]+k];let y=flat[starts[j]+k]
        if x!=y:return x<y
    return False
@export("numeric_string_sort")
fn numeric_string_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>2114:return -1
    let count=a[0]
    if count<0 or count>64:return -1
    var flat=InlineArray[UInt8,2048]();var starts=InlineArray[Int,64]();var lens=InlineArray[Int,64]();var norms=InlineArray[Int,64]();var pos=0
    for i in range(Int(count)):
        if pos>=Int(n):return -1
        let length=a[pos];pos+=1
        if length<1 or length>32 or pos+Int(length)>Int(n):return -1
        starts[i]=pos;lens[i]=Int(length)
        for j in range(Int(length)):
            let c=a[pos+j]
            if c<48 or c>57:return -1
            flat[i*32+j]=UInt8(c)
        var leading=0
        while leading<Int(length)-1 and flat[i*32+leading]==48:leading+=1
        norms[i]=Int(length)-leading
        starts[i]=i*32+leading
        pos+=Int(length)
    if pos!=n:return -1
    for i in range(Int(count)):
        for j in range(i+1,Int(count)):
            var eq=norms[i]==norms[j]
            if eq:
                for k in range(norms[i]):if flat[starts[i]+k]!=flat[starts[j]+k]:eq=False
            if eq and lens[i]!=lens[j]:return -1
            if eq and lens[i]==lens[j]:
                var same=true
                for k in range(Int(lens[i])):if flat[i*32+k]!=flat[j*32+k]:same=false
                if not same:return -1
    var order=InlineArray[Int,64]()
    for i in range(Int(count)):order[i]=i
    for i in range(1,Int(count)):
        let current=order[i];var j=i
        while j>0 and nss_less(flat,starts,lens,norms,current,order[j-1]):order[j]=order[j-1];j-=1
        order[j]=current
    var staged=InlineArray[UInt8,2111]();var outlen=0
    for oi in range(Int(count)):
        let idx=order[oi]
        if oi>0:staged[outlen]=UInt8(32);outlen+=1
        for j in range(Int(lens[idx])):staged[outlen]=flat[idx*32+j];outlen+=1
    if (outlen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()) or cap<c_size_t(outlen):return -2
    for i in range(outlen):o[i]=staged[i]
    return Int64(outlen)
