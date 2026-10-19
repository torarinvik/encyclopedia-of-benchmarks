from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn look_hash(h0:UInt64,x:Int64)->UInt64:
    var h=h0;let b=UInt64(x)
    for i in range(8):h=(h^UInt64((b>>(8*i))&255))*UInt64(1099511628211)
    return h
@export("look_scheduling")
fn look_scheduling(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>4100:return -1
    let maxtrack=v[0];let start=v[1];let direction=v[2];let count=v[3]
    if maxtrack<1 or maxtrack>256 or start<0 or start>=maxtrack or (direction!=0 and direction!=1) or count<0 or count>4096 or n!=c_size_t(count+4):return -1
    var low=InlineArray[Int64,256](fill=0);var high=InlineArray[Int64,256](fill=0);var farthest:Int64=0
    for i in range(Int(count)):
        let r=v[4+i]
        if r < -2147483648 or r>2147483647:return -1
        if r>=0 and r<maxtrack:
            if r<start:low[r]+=1
            else:high[r]+=1
            farthest=max(farthest,r)
    var route=InlineArray[Int64,4096](fill=0);var rc=0
    if direction==1:
        for track in range(Int(start),Int(maxtrack)):
            for _ in range(Int(high[track])):route[rc]=Int64(track);rc+=1
        var track=Int(start)
        while track>0:
            track-=1
            for _ in range(Int(low[track])):route[rc]=Int64(track);rc+=1
    else:
        var track=Int(start)
        while track>0:
            track-=1
            for _ in range(Int(low[track])):route[rc]=Int64(track);rc+=1
        for track in range(Int(start),Int(maxtrack)):
            for _ in range(Int(high[track])):route[rc]=Int64(track);rc+=1
    var hash=look_hash(UInt64(14695981039346656037),Int64(rc))
    for i in range(rc):hash=look_hash(hash,route[i])
    hash=look_hash(hash,if direction==1:0 else:1);hash=look_hash(hash,farthest);hash=look_hash(hash,start)
    return Int64(hash&UInt64(0x7fffffffffffffff))
