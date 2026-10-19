from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mos_hash_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("mos_algorithm")
fn mos_algorithm(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>1285:return -1
    let op=Int(v[0]);let count=Int(v[1]);let q=Int(v[2]);let target=v[3]
    if (op!=0 and op!=1) or count<1 or count>256 or q<0 or q>256 or target < -1000000 or target>1000000 or Int(n)!=4+count+3*q:return -1
    var data=InlineArray[Int32,256](fill=0);var left=InlineArray[Int32,256](fill=0);var right=InlineArray[Int32,256](fill=0);var ix=InlineArray[Int32,256](fill=0);var order=InlineArray[Int32,256](fill=0);var seen=InlineArray[Int64,256](fill=0)
    for i in range(count):let x=v[4+i];if x < -1000000 or x>1000000:return -1;data[i]=Int32(x)
    let qo=4+count
    for j in range(q):
        let l=v[qo+3*j];let r=v[qo+3*j+1];let k=v[qo+3*j+2]
        if l<0 or r<l or r>=count or k<0 or k>=q or seen[Int(k)]!=0:return -1
        left[j]=Int32(l);right[j]=Int32(r);ix[j]=Int32(k);seen[Int(k)]=1;order[j]=Int32(j)
    var block=1;while (block+1)*(block+1)<=count:block+=1
    for i in range(1,q):
        let key=order[i];var j=i
        while j>0:
            let a=Int(order[j-1]);let b=Int(key);let ba=Int(left[a])/block;let bb=Int(left[b])/block
            let before=if ba!=bb:ba<bb elif ba%2==1:right[b]<right[a] else:right[b]>right[a]
            if not before:break
            order[j]=order[j-1];j-=1
        order[j]=key
    var ans=InlineArray[Int32,256](fill=0);var cl=0;var cr=-1;var agg:Int32=0
    for z in range(q):
        let j=Int(order[z]);let l=left[j];let r=right[j]
        if op==0:
            while cr<r:cr+=1;agg+=data[Int(cr)]
            while cr>r:agg-=data[Int(cr)];cr-=1
            while cl<l:agg-=data[Int(cl)];cl+=1
            while cl>l:cl-=1;agg+=data[Int(cl)]
        else:
            while cr<r:cr+=1;if data[Int(cr)]==Int32(target):agg+=1
            while cr>r:if data[Int(cr)]==Int32(target):agg-=1;cr-=1
            while cl<l:if data[Int(cl)]==Int32(target):agg-=1;cl+=1
            while cl>l:cl-=1;if data[Int(cl)]==Int32(target):agg+=1
        ans[Int(ix[j])]=agg
    var h:UInt64=14695981039346656037;h=mos_hash_byte(h,UInt8(op));h=mos_hash_byte(h,UInt8(q&255));h=mos_hash_byte(h,UInt8((q>>8)&255))
    for i in range(q):let u=UInt32(ans[i]);for b in range(4):h=mos_hash_byte(h,UInt8((u>>(8*b))&255))
    return Int64(h&0x7fffffffffffffff)
