from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sk_merge(v:UnsafePointer[Int64,MutAnyOrigin],l:UnsafePointer[Int32,MutAnyOrigin],r:UnsafePointer[Int32,MutAnyOrigin],a:Int32,b:Int32)->Int32:
    if a<0:return b
    if b<0:return a
    var x=a;var y=b
    if v[x]>v[y]:let t=x;x=y;y=t
    let merged=sk_merge(v,l,r,r[x],y);r[x]=l[x];l[x]=merged
    return x
fn sk_write(o:UnsafePointer[UInt8,MutAnyOrigin],off:Int,val:Int64):
    let bits=UInt64(val);for b in range(8):o[off+b]=UInt8((bits>>(b*8))&255)
@export("skew_heap")
fn skew_heap(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let ops=a[0];if ops<0 or ops>64 or n!=c_size_t(1+2*ops):return -1
    var vals=InlineArray[Int64,64]();var left=InlineArray[Int32,64]();var right=InlineArray[Int32,64]();var root:Int32=-1;var used=0;var live=0
    var result=InlineArray[Int64,1024]();var rn=0
    for i in range(Int(ops)):
        let op=a[1+2*i];let x=a[2+2*i]
        if op<0 or op>5 or (op!=0 and x!=0):return -1
        if op==0:
            if x< -2147483648 or x>2147483647 or live>=32 or used>=64:return -1
            vals[used]=x;left[used]= -1;right[used]= -1;root=sk_merge(vals.unsafe_ptr(),left.unsafe_ptr(),right.unsafe_ptr(),root,Int32(used));used+=1;live+=1
        elif op==1 or op==2:
            if live==0:return -1
            result[rn]=vals[root];rn+=1
            if op==2:root=sk_merge(vals.unsafe_ptr(),left.unsafe_ptr(),right.unsafe_ptr(),left[root],right[root]);live-=1
        elif op==3:
            var snap=InlineArray[Int64,32]();let old=live
            for j in range(old):snap[j]=vals[root];result[rn]=vals[root];rn+=1;root=sk_merge(vals.unsafe_ptr(),left.unsafe_ptr(),right.unsafe_ptr(),left[root],right[root]);live-=1
            used=0
            for j in range(old):
                vals[used]=snap[j];left[used]= -1;right[used]= -1;root=sk_merge(vals.unsafe_ptr(),left.unsafe_ptr(),right.unsafe_ptr(),root,Int32(used));used+=1;live+=1
        elif op==4:root= -1;live=0
        else:result[rn]=1 if live==0 else 0;rn+=1
    let bytes=rn*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rn):sk_write(o,i*8,result[i])
    return bytes
