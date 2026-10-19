from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ipq_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):o[p+8*b]=UInt8((u>>(8*b))&255)
@export("indexed_priority_queue")
fn indexed_priority_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1538 or v[0]<0 or v[0]>256 or Int(n)!=1+6*Int(v[0]):return -1
    let count=Int(v[0]);if count==0:return 0
    var active=InlineArray[Int64,64](fill=0);var keys=InlineArray[Int64,64](fill=0);var records=InlineArray[Int64,1536](fill=0)
    for ev in range(count):
        let p=1+ev*6;let op=v[p];let rawid=v[p+1];let key=v[p+2]
        if v[p+3]!=0 or v[p+4]!=0 or v[p+5]!=0:return -1
        var status:Int64=1;var result_id:Int64=0;var result_key:Int64=0
        if op==0:
            if rawid<0 or rawid>=64 or key < -2147483648 or key>2147483647 or active[Int(rawid)]!=0:return -1
            for i in range(64):if active[i]!=0 and keys[i]==key:return -1
            active[Int(rawid)]=1;keys[Int(rawid)]=key
        elif op==1 or op==2:
            if rawid!=0 or key!=0:return -1
            var best=-1
            for i in range(64):if active[i]!=0 and (best<0 or keys[i]<keys[best]):best=i
            if best<0:status=0
            else:result_id=Int64(best);result_key=keys[best];if op==2:active[best]=0
        elif op==3 or op==4:
            if rawid<0 or rawid>=64 or key!=0:return -1
            status=active[Int(rawid)];if op==3 and status==1:active[Int(rawid)]=0
        elif op>=5 and op<=7:
            if rawid<0 or rawid>=64 or key < -2147483648 or key>2147483647 or active[Int(rawid)]==0:return -1
            let id=Int(rawid);let old=keys[id]
            if (op==6 and key>=old) or (op==7 and key<=old):return -1
            for i in range(64):if i!=id and active[i]!=0 and keys[i]==key:return -1
            keys[id]=key
        elif op==8 or op==9 or op==10:
            if rawid!=0 or key!=0:return -1
            if op==8:for i in range(64):active[i]=0
            elif op==9:for i in range(64):if active[i]!=0:result_id+=1
            else:
                var size=0
                for i in range(64):if active[i]!=0:size+=1
                result_id=1 if size==0 else 0
        else:return -1
        var size=0;var best=-1
        for i in range(64):
            if active[i]!=0:size+=1
            if active[i]!=0 and (best<0 or keys[i]<keys[best]):best=i
        let off=ev*6;records[off]=status;records[off+1]=result_id;records[off+2]=result_key;records[off+3]=Int64(size);records[off+4]=if best<0:0 else:Int64(best);records[off+5]=if best<0:0 else:keys[best]
    let bytes=count*48;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count*6):ipq_put(o,8*i,records[i])
    return Int64(bytes)
