from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime S=64
comptime MAX=4161
fn ns_char(buf:InlineArray[Int64,4096],idx:Int,pos:Int)->Int64:
    let c=buf[idx*S+pos]
    return c+32 if c>=65 and c<=90 else c
fn ns_before(buf:InlineArray[Int64,4096],lens:InlineArray[Int64,64],prefix:InlineArray[Int64,64],has:InlineArray[Bool,64],sufstart:InlineArray[Int64,64],left:Int,right:Int)->Bool:
    let lp=Int(prefix[left]);let rp=Int(prefix[right]);let common=min(lp,rp)
    for i in range(common):
        let a=ns_char(buf,left,i);let b=ns_char(buf,right,i)
        if a<b:return True
        if a>b:return False
    if lp!=rp:return lp<rp
    if has[left]!=has[right]:return not has[left]
    if not has[left]:return False
    var ls=Int(sufstart[left]);var rs=Int(sufstart[right]);let le=Int(lens[left]);let re=Int(lens[right])
    while ls<le and buf[left*S+ls]==48:ls+=1
    while rs<re and buf[right*S+rs]==48:rs+=1
    let ln=le-ls;let rn=re-rs
    if ln!=rn:return ln<rn
    for i in range(ln):
        let a=buf[left*S+ls+i];let b=buf[right*S+rs+i]
        if a<b:return True
        if a>b:return False
    return False
@export("natural_sort")
fn natural_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4161 or a[0]<0 or a[0]>64:return -1
    let count=Int(a[0]);var pos=1;var buf=InlineArray[Int64,4096]();var lens=InlineArray[Int64,64]();var prefix=InlineArray[Int64,64]();var has=InlineArray[Bool,64]();var suf=InlineArray[Int64,64]();var order=InlineArray[Int64,64]()
    for id in range(count):
        if pos>=Int(n):return -1
        let len=a[pos];pos+=1;if len<0 or len>64 or pos+Int(len)>Int(n):return -1
        lens[id]=len;order[id]=id
        var i=0;var saw_digit=False
        while i<Int(len):
            let c=a[pos+i]
            if c<0 or c>127:return -1
            if c>=48 and c<=57:
                saw_digit=True
            elif (c>=65 and c<=90) or (c>=97 and c<=122):
                if saw_digit:return -1
            else:return -1
            buf[id*S+i]=c;i+=1
        var p=0
        while p<Int(len) and not (buf[id*S+p]>=48 and buf[id*S+p]<=57):p+=1
        if Int(len)>0 and p==0:return -1
        prefix[id]=p
        if p<Int(len):has[id]=True;suf[id]=p
        pos+=Int(len)
    if pos!=Int(n):return -1
    for i in range(1,count):
        let value=order[i];var j=i
        while j>0 and ns_before(buf,lens,prefix,has,suf,Int(value),Int(order[j-1])):order[j]=order[j-1];j-=1
        order[j]=value
    var bytes=InlineArray[UInt8,4160]();var outlen=0
    for oi in range(count):
        if oi>0:bytes[outlen]=10;outlen+=1
        let id=Int(order[oi]);for j in range(Int(lens[id])):bytes[outlen]=UInt8(buf[id*S+j]);outlen+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    for i in range(outlen):o[i]=bytes[i]
    return outlen
