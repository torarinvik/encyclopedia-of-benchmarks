from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hash_map_open_addressing")
fn hash_map_open_addressing(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let ops=a[0];if ops<0 or ops>256 or n!=c_size_t(1+3*ops):return -1
    var keys=InlineArray[Int64,512](fill=0);var vals=InlineArray[Int64,512](fill=0);var states=InlineArray[Int,512](fill=0)
    var cap=8;var size=0;var query_index=0;var result:Int64=0
    for i in range(Int(ops)):
        let op=Int(a[1+3*i]);let key=a[2+3*i];let value=a[3+3*i]
        if key<0 or key>1000000 or value< -1000000 or value>1000000 or op<0 or op>4:return -1
        if op==4:
            if key!=0 or value!=0:return -1
            result+=Int64(query_index+1)*(Int64(size)+1000001);query_index+=1;continue
        if (op==1 or op==2 or op==3) and value!=0:return -1
        if op==0:
            if size>=cap*3//4:
                let newcap=cap*2;var nk=InlineArray[Int64,512](fill=0);var nv=InlineArray[Int64,512](fill=0);var ns=InlineArray[Int,512](fill=0)
                for old in range(cap):
                    if states[old]==1:
                        let start=Int(keys[old])%newcap
                        for step in range(newcap):
                            let slot=(start+step)%newcap
                            if ns[slot]==0:nk[slot]=keys[old];nv[slot]=vals[old];ns[slot]=1;break
                keys=nk;vals=nv;states=ns;cap=newcap
            var ix=Int(key)%cap;var first_tomb=-1;var found=-1
            for step in range(cap):
                let slot=(ix+step)%cap
                if states[slot]==0:break
                if states[slot]==2 and first_tomb<0:first_tomb=slot
                if states[slot]==1 and keys[slot]==key:found=slot;break
            if found>=0:
                if first_tomb>=0:return -1
                vals[found]=value
            else:
                let slot=first_tomb if first_tomb>=0 else ix
                var actual=slot
                if first_tomb<0:
                    for step in range(cap):
                        let s=(ix+step)%cap
                        if states[s]==0:actual=s;break
                states[actual]=1;keys[actual]=key;vals[actual]=value;size+=1
            if size>64:return -1
        elif op==1 or op==2 or op==3:
            var ix=Int(key)%cap;var found=-1
            for step in range(cap):
                let slot=(ix+step)%cap
                if states[slot]==0:break
                if states[slot]==1 and keys[slot]==key:found=slot;break
            if (op==1 or op==2) and found<0:return -1
            var ans:Int64=0
            if op==1:ans=vals[found]
            elif op==3:ans=1 if found>=0 else 0
            result+=Int64(query_index+1)*(ans+1000001);query_index+=1
            if op==2:
                states[found]=2;size-=1
                if cap>8 and Float64(size)<Float64(cap)*0.75/2.0:
                    let newcap=cap//2;var nk=InlineArray[Int64,512](fill=0);var nv=InlineArray[Int64,512](fill=0);var ns=InlineArray[Int,512](fill=0)
                    for old in range(cap):
                        if states[old]==1:
                            let start=Int(keys[old])%newcap
                            for step in range(newcap):
                                let slot=(start+step)%newcap
                                if ns[slot]==0:nk[slot]=keys[old];nv[slot]=vals[old];ns[slot]=1;break
                    keys=nk;vals=nv;states=ns;cap=newcap
    var previous:Int64= -1
    for rank in range(size):
        var best=-1
        for slot in range(cap):
            if states[slot]==1 and keys[slot]>previous and (best<0 or keys[slot]<keys[best]):best=slot
        if best>=0:result+=Int64(rank+1)*(keys[best]+1)*(vals[best]+1000001);previous=keys[best]
    return result+Int64(size)
