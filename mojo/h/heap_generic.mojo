from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hg_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("heap_generic")
fn heap_generic(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let ops=a[0];if ops<0 or ops>512 or n!=c_size_t(1+3*ops):return -1
    var ids=InlineArray[Int64,128](fill=0);var pr=InlineArray[Int64,128](fill=0);var used=InlineArray[Bool,4096](fill=false);var size=0
    var h:UInt64=14695981039346656037
    for oi in range(Int(ops)):
        let op=Int(a[1+3*oi]);let id=a[2+3*oi];let p=a[3+3*oi]
        if op<0 or op>4:return -1
        var present=false;var rid:Int64=0;var rp:Int64=0
        if op==0:
            if id<0 or id>4095 or used[Int(id)] or size>=128 or p< -2147483648 or p>2147483647:return -1
            for j in range(size):if pr[j]==p:return -1
            used[Int(id)]=true;ids[size]=id;pr[size]=p;size+=1
            var cur=size-1
            while cur>0:
                let parent=(cur-1)//2
                if pr[parent]>=pr[cur]:break
                let ti=ids[parent];ids[parent]=ids[cur];ids[cur]=ti
                let tp=pr[parent];pr[parent]=pr[cur];pr[cur]=tp;cur=parent
        elif op==1 or op==2:
            if id!=0 or p!=0:return -1
            if size>0:present=true;rid=ids[0];rp=pr[0]
            if op==2 and size>0:
                size-=1;ids[0]=ids[size];pr[0]=pr[size];var cur=0
                while cur*2+1<size:
                    var child=cur*2+1
                    if child+1<size and pr[child+1]>pr[child]:child+=1
                    if pr[cur]>=pr[child]:break
                    let ti=ids[cur];ids[cur]=ids[child];ids[child]=ti
                    let tp=pr[cur];pr[cur]=pr[child];pr[child]=tp;cur=child
        elif op==3:
            if id<0 or id>4095 or p< -2147483648 or p>2147483647:return -1
            var ix=-1
            for j in range(size):if ids[j]==id:ix=j
            if ix<0:return -1
            for j in range(size):if j!=ix and pr[j]==p:return -1
            pr[ix]=p;var cur=ix
            while cur>0:
                let parent=(cur-1)//2
                if pr[parent]>=pr[cur]:break
                let ti=ids[parent];ids[parent]=ids[cur];ids[cur]=ti
                let tp=pr[parent];pr[parent]=pr[cur];pr[cur]=tp;cur=parent
            cur=ix
            while cur*2+1<size:
                var child=cur*2+1
                if child+1<size and pr[child+1]>pr[child]:child+=1
                if pr[cur]>=pr[child]:break
                let ti=ids[cur];ids[cur]=ids[child];ids[child]=ti
                let tp=pr[cur];pr[cur]=pr[child];pr[child]=tp;cur=child
        else:
            if id<0 or id>4095 or p!=0:return -1
            var ix=-1
            for j in range(size):if ids[j]==id:ix=j
            if ix<0:return -1
            size-=1;ids[ix]=ids[size];pr[ix]=pr[size];var cur=ix
            while cur>0:
                let parent=(cur-1)//2
                if pr[parent]>=pr[cur]:break
                let ti=ids[parent];ids[parent]=ids[cur];ids[cur]=ti
                let tp=pr[parent];pr[parent]=pr[cur];pr[cur]=tp;cur=parent
            cur=ix
            while cur*2+1<size:
                var child=cur*2+1
                if child+1<size and pr[child+1]>pr[child]:child+=1
                if pr[cur]>=pr[child]:break
                let ti=ids[cur];ids[cur]=ids[child];ids[child]=ti
                let tp=pr[cur];pr[cur]=pr[child];pr[child]=tp;cur=child
        h=hg_byte(h,UInt8(op));h=hg_byte(h,1 if present else 0)
        if present:
            let ui=bitcast[UInt32](Int32(rid));let up=bitcast[UInt32](Int32(rp))
            for b in range(4):h=hg_byte(h,UInt8((ui>>UInt(8*b))&255))
            for b in range(4):h=hg_byte(h,UInt8((up>>UInt(8*b))&255))
    return bitcast[Int64](h)
