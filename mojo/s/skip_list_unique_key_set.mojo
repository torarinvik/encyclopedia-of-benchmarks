from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn slu_put(o:UnsafePointer[UInt8,MutAnyOrigin],off:Int,v:Int64):
    let b=UInt64(v);for i in range(8):o[off+i]=UInt8((b>>(i*8))&255)
fn slu_height(key:Int64)->Int:
    let h=bitcast[UInt32](Int32(key*2654435761));var k=1;var v=h
    while k<8 and (v&1)==0:k+=1;v>>=1
    return k
fn slu_find(keys:UnsafePointer[Int64,MutAnyOrigin],links:UnsafePointer[Int32,MutAnyOrigin],level:Int,head:Int32,key:Int64,update:UnsafePointer[Int32,MutAnyOrigin])->Int32:
    var cur=head
    for lv in range(level-1,-1,-1):
        var nxt=links[Int(cur)*8+lv]
        while nxt>=0 and keys[nxt]<key:cur=nxt;nxt=links[Int(cur)*8+lv]
        update[lv]=cur
    return links[Int(cur)*8]
@export("skip_list_unique_key_set")
fn skip_list_unique_key_set(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let ops=a[0];if ops<0 or ops>128 or n!=c_size_t(1+2*ops):return -1
    var keys=InlineArray[Int64,128]();var links=InlineArray[Int32,1032]();var update=InlineArray[Int32,8]();var heights=InlineArray[Int32,128]()
    for i in range(1032):links[i]= -1
    let head:Int32=128;var top=1;var used=0
    for i in range(Int(ops)):
        let op=a[1+2*i];let key=a[2+2*i];if op<0 or op>2 or key< -2147483647 or key>2147483646:return -1
        let next=slu_find(keys.unsafe_ptr(),links.unsafe_ptr(),top,head,key,update.unsafe_ptr())
        let found=next>=0 and keys[next]==key
        if op==0:
            if found or used>=128:return -1
            let h=slu_height(key);keys[used]=key;heights[used]=Int32(h)
            if h>top:
                for lv in range(top,h):update[lv]=head
                top=h
            for lv in range(h):links[used*8+lv]=links[Int(update[lv])*8+lv];links[Int(update[lv])*8+lv]=Int32(used)
            used+=1
        elif op==2:
            if not found:return -1
            for lv in range(top):
                if links[Int(update[lv])*8+lv]==next:links[Int(update[lv])*8+lv]=links[Int(next)*8+lv]
            while top>1 and links[Int(head)*8+top-1]<0:top-=1
        else:pass
    var count=0;var cur=links[Int(head)*8]
    while cur>=0:count+=1;cur=links[Int(cur)*8]
    let bytes=count*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    cur=links[Int(head)*8];var p=0
    while cur>=0:slu_put(o,p*8,keys[cur]);p+=1;cur=links[Int(cur)*8]
    return bytes
