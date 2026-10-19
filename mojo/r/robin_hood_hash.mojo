from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn put64rh(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(j*8))&UInt64(255))
@export("robin_hood_hash")
fn robin_hood_hash(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>193 or v[0]<0 or v[0]>64 or Int(n)!=1+3*Int(v[0]):return -1
    let q=Int(v[0]);var keys=InlineArray[Int64,16](fill=0);var vals=InlineArray[Int64,16](fill=0);var psls=InlineArray[Int64,16](fill=0);var used=InlineArray[Bool,16](fill=False);var count=0
    var results=InlineArray[Int64,64](fill=0)
    for opidx in range(q):
        let at=1+3*opidx;let op=v[at];let rawkey=v[at+1];let rawval=v[at+2]
        if op==0:
            if rawkey<0 or rawkey>4294967295 or rawval<100 or rawval>1000000:return -1
            if (count*100)/16>=90:return -1
            var key=rawkey;var value=rawval;var psl=0;let hashed=bitcast[UInt64](key)*UInt64(0x9E3779B97F4A7C15);var idx=Int((hashed>>32)&UInt64(15));var probes=0;var done=False
            while probes<64:
                if not used[idx]:keys[idx]=key;vals[idx]=value;psls[idx]=psl;used[idx]=True;count+=1;done=True;break
                if keys[idx]==key:vals[idx]=value;done=True;break
                if psl>psls[idx]:
                    let tk=keys[idx];let tv=vals[idx];let tp=psls[idx]
                    keys[idx]=key;vals[idx]=value;psls[idx]=psl
                    key=tk;value=tv;psl=tp
                psl+=1;idx=(idx+1)&15;probes+=1
            if not done or count>14:return -1
            results[opidx]= -2
        elif op==1 or op==2:
            if rawkey<0 or rawkey>4294967295 or rawval!=0:return -1
            let hashed=bitcast[UInt64](rawkey)*UInt64(0x9E3779B97F4A7C15);var idx=Int((hashed>>32)&UInt64(15));var psl=0;var found= -1
            while psl<64:
                if not used[idx] or psl>psls[idx]:break
                if keys[idx]==rawkey:found=idx;break
                idx=(idx+1)&15;psl+=1
            if op==1:results[opidx]=if found<0: -1 else:vals[found]
            else:
                if found<0:results[opidx]=0
                else:
                    var ix=found
                    for _ in range(16):
                        let next=(ix+1)&15
                        if not used[next] or psls[next]==0:used[ix]=False;psls[ix]=0;break
                        keys[ix]=keys[next];vals[ix]=vals[next];psls[ix]=psls[next]-1;used[ix]=True;ix=next
                    count-=1;results[opidx]=1
        elif op>=3 and op<=7:
            if rawkey!=0 or rawval!=0:return -1
            if op==3:results[opidx]=Int64(count)
            elif op==4:results[opidx]=Int64((count*100)/16)
            elif op==5:
                var maxpsl=0
                for j in range(16):if used[j] and psls[j]>maxpsl:maxpsl=Int(psls[j])
                results[opidx]=Int64(maxpsl)
            elif op==6:
                for j in range(16):used[j]=False;psls[j]=0
                count=0;results[opidx]= -3
            else:results[opidx]=if count==0:1 else:0
        else:return -1
    let bytes=q*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(q):put64rh(o,i*8,results[i])
    return Int64(bytes)
