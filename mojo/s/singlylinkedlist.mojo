from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sll_put(o:UnsafePointer[UInt8,MutAnyOrigin],off:Int,v:Int64):
    let bits=UInt64(v);for b in range(8):o[off+b]=UInt8((bits>>(b*8))&255)
fn sll_alloc(v:Int64,vals:UnsafePointer[Int64,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],used0:Int)->Int32:
    vals[used0]=v;next[used0]= -1;return Int32(used0)
fn sll_head(v:Int64,vals:UnsafePointer[Int64,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],used:UnsafePointer[Int32,MutAnyOrigin],head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],size:UnsafePointer[Int32,MutAnyOrigin]):
    let node=sll_alloc(v,vals,next,Int(used[0]));used[0]+=1;next[node]=head[0]
    if head[0]<0:tail[0]=node
    head[0]=node;size[0]+=1
fn sll_tail(v:Int64,vals:UnsafePointer[Int64,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],used:UnsafePointer[Int32,MutAnyOrigin],head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],size:UnsafePointer[Int32,MutAnyOrigin]):
    let node=sll_alloc(v,vals,next,Int(used[0]));used[0]+=1
    if tail[0]<0:head[0]=node
    else:next[tail[0]]=node
    tail[0]=node;size[0]+=1
fn sll_delhead(vals:UnsafePointer[Int64,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],size:UnsafePointer[Int32,MutAnyOrigin])->Int64:
    let node=head[0];let value=vals[node];head[0]=next[node];size[0]-=1
    if size[0]==0:tail[0]= -1
    return value
fn sll_deltail(vals:UnsafePointer[Int64,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],size:UnsafePointer[Int32,MutAnyOrigin])->Int64:
    let node=tail[0];let value=vals[node]
    if size[0]==1:head[0]= -1;tail[0]= -1
    else:
        var prev=head[0];while next[prev]!=tail[0]:prev=next[prev]
        next[prev]= -1;tail[0]=prev
    size[0]-=1;return value
fn sll_reverse(head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin]):
    var prev:Int32= -1;var cur=head[0];tail[0]=head[0]
    while cur>=0:let following=next[cur];next[cur]=prev;prev=cur;cur=following
    head[0]=prev
fn sll_reverse_range(head:UnsafePointer[Int32,MutAnyOrigin],tail:UnsafePointer[Int32,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],left:Int,right:Int,size:Int):
    var before:Int32= -1;var start=head[0]
    for _ in range(1,left):before=start;start=next[start]
    var prev:Int32= -1;var cur=start
    for _ in range(left,right+1):let following=next[cur];next[cur]=prev;prev=cur;cur=following
    next[start]=cur
    if before<0:head[0]=prev
    else:next[before]=prev
    if right==size:tail[0]=start
@export("singlylinkedlist")
fn singlylinkedlist(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>227:return -1
    let ic=a[0];let oc=a[1];if ic<0 or ic>32 or oc<0 or oc>64 or n<c_size_t(2+ic):return -1
    var vals=InlineArray[Int64,96]();var next=InlineArray[Int32,96]();var used=InlineArray[Int32,1]();var head=InlineArray[Int32,1]();var tail=InlineArray[Int32,1]();var size=InlineArray[Int32,1]();head[0]= -1;tail[0]= -1
    var cursor=2
    for i in range(Int(ic)):
        let v=a[cursor];cursor+=1;if v< -1000000 or v>1000000:return -1
        sll_tail(v,vals.unsafe_ptr(),next.unsafe_ptr(),used.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
    var result=InlineArray[Int64,128]()
    for oi in range(Int(oc)):
        if cursor>=Int(n):return -1
        let op=a[cursor];cursor+=1;var x:Int64=0;var y:Int64=0
        if op==0 or op==1 or op==4:
            if cursor>=Int(n):return -1
            x=a[cursor];cursor+=1
        elif op==6:
            if cursor+1>=Int(n):return -1
            x=a[cursor];y=a[cursor+1];cursor+=2
        elif op!=2 and op!=3 and op!=5:return -1
        var success:Int64=1;var value:Int64=0
        if op==0 or op==1:
            if x< -1000000 or x>1000000:return -1
            if op==0:sll_head(x,vals.unsafe_ptr(),next.unsafe_ptr(),used.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
            else:sll_tail(x,vals.unsafe_ptr(),next.unsafe_ptr(),used.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
        elif op==2:
            if size[0]==0:success=0
            else:value=sll_delhead(vals.unsafe_ptr(),next.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
        elif op==3:
            if size[0]==0:success=0
            else:value=sll_deltail(vals.unsafe_ptr(),next.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
        elif op==4:
            if size[0]==0:
                if x!=1:return -1
                success=0
            else:
                if x<1 or x>size[0]+1:return -1
                if x==1:value=sll_delhead(vals.unsafe_ptr(),next.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
                elif x>=size[0]:value=sll_deltail(vals.unsafe_ptr(),next.unsafe_ptr(),head.unsafe_ptr(),tail.unsafe_ptr(),size.unsafe_ptr())
                else:
                    var prev=head[0];for _ in range(1,Int(x)-1):prev=next[prev]
                    let node=next[prev];value=vals[node];next[prev]=next[node];size[0]-=1
        elif op==5:sll_reverse(head.unsafe_ptr(),tail.unsafe_ptr(),next.unsafe_ptr())
        else:
            if x<1 or y<x or y>size[0]:return -1
            sll_reverse_range(head.unsafe_ptr(),tail.unsafe_ptr(),next.unsafe_ptr(),Int(x),Int(y),Int(size[0]))
        result[oi*2]=success;result[oi*2+1]=value
    if cursor!=Int(n):return -1
    let bytes=(1+Int(size[0])+1+Int(oc)*2)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    sll_put(o,0,Int64(size[0]));var cur=head[0];var p=8
    while cur>=0:sll_put(o,p,vals[cur]);p+=8;cur=next[cur]
    sll_put(o,p,oc);p+=8
    for i in range(Int(oc)*2):sll_put(o,p+8*i,result[i])
    return bytes
