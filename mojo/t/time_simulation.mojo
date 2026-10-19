from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tsim_hash(inout h:UInt64,w:UInt64):
    for shift in range(0,64,8):
        h=h^((w>>UInt64(shift))&255)
        h=h*1099511628211
@export("time_simulation")
fn time_simulation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>8194:return -1
    let actions=a[0]
    if actions<0 or actions>4096 or n!=c_size_t(1+2*actions):return -1
    var now:Int64=0;var nextid:UInt64=1;var active_count=0;var total=0;var fired=0
    var active=InlineArray[Bool,1024]();var times=InlineArray[Int64,1024]();var ids=InlineArray[UInt64,1024]()
    var fids=InlineArray[UInt64,4096]();var ftimes=InlineArray[Int64,4096]();var hash:UInt64=14695981039346656037
    tsim_hash(hash,UInt64(actions))
    for action in range(Int(actions)):
        let op=a[1+2*action];let arg=a[2+2*action];var result:UInt64=0
        if op==0:
            if arg<0 or arg<now:return -1
            if active_count<1024:
                var slot=0
                while active[slot]:slot+=1
                active[slot]=True;times[slot]=arg;ids[slot]=nextid;active_count+=1;result=nextid;nextid+=1
                if nextid>4294967295:nextid=1
        elif op==1:
            if arg<1 or arg>4294967295:return -1
            for slot in range(1024):
                if active[slot] and ids[slot]==UInt64(arg):active[slot]=False;active_count-=1;result=1;break
        elif op==2:
            if arg<0 or arg<now:return -1
            var processed=0
            while True:
                var chosen=-1;var earliest:Int64=0
                for slot in range(1024):
                    if active[slot] and times[slot]<=arg and (chosen<0 or times[slot]<earliest):chosen=slot;earliest=times[slot]
                if chosen<0:break
                now=times[chosen];active[chosen]=False;active_count-=1
                fids[fired]=ids[chosen];ftimes[fired]=times[chosen];fired+=1;processed+=1;total+=1
            now=arg;result=UInt64(processed)
        elif op==3:
            if arg!=0:return -1
            result=UInt64(now)
        elif op==4:
            if arg!=0:return -1
            result=UInt64(1 if active_count==0 else 0)
        else:return -1
        tsim_hash(hash,result)
    tsim_hash(hash,UInt64(fired))
    for i in range(fired):tsim_hash(hash,fids[i]);tsim_hash(hash,UInt64(ftimes[i]))
    tsim_hash(hash,UInt64(now));tsim_hash(hash,UInt64(active_count));tsim_hash(hash,UInt64(total))
    return Int64(hash&9223372036854775807)
