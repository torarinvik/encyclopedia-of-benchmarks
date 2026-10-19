from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sol_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("self_organizing_linked_list")
fn self_organizing_linked_list(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(1+2*count):return -1
    var values=InlineArray[Int64,64]();var next=InlineArray[Int32,64]();var used=0;var head:Int32=-1;var tail:Int32=-1;var size=0
    var rec=InlineArray[Int64,194]();var rp=0
    for i in range(Int(count)):
        let op=a[1+2*i];let value=a[2+2*i];if value< -2147483648 or value>2147483647:return -1
        if op==0:
            if size>=64:return -1
            values[used]=value;next[used]= -1
            if tail<0:head=Int32(used)
            else:next[tail]=Int32(used)
            tail=Int32(used);used+=1;size+=1;rec[rp]=0;rec[rp+1]=0;rp+=2
        elif op==1:
            var prev:Int32=-1;var cur=head
            while cur>=0 and values[cur]!=value:prev=cur;cur=next[cur]
            let found=1 if cur>=0 else 0;rec[rp]=1;rec[rp+1]=1;rec[rp+2]=found;rp+=3
            if cur>=0 and cur!=head:
                next[prev]=next[cur]
                if cur==tail:tail=prev
                next[cur]=head;head=cur
        else:return -1
    rec[rp]=2;rec[rp+1]=size;rp+=2
    var cur=head;while cur>=0:rec[rp]=values[cur];rp+=1;cur=next[cur]
    let bytes=rp*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rp):sol_put(o,i*8,rec[i])
    return bytes
