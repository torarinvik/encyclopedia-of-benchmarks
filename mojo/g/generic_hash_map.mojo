from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gh_hash(h0:UInt64,val:Int64)->UInt64:
    var h=h0;let x=bitcast[UInt64](val)
    for i in range(8):h=(h^((x>>UInt64(8*i))&255))*UInt64(0x100000001b3)
    return h
@export("generic_hash_map")
fn generic_hash_map(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>385 or v[0]<0 or v[0]>128 or n!=c_size_t(1+3*v[0]):return -1
    var keys=InlineArray[Int64,64](fill=0);var vals=InlineArray[Int64,64](fill=0);var active=InlineArray[Bool,64](fill=False)
    var next=InlineArray[Int,64](fill= -1);var bucket=InlineArray[Int,128](fill= -1)
    var size=0;var bucket_count=16;var hash=UInt64(0xcbf29ce484222325)
    for oi in range(Int(v[0])):
        let op=v[1+3*oi];let key=v[2+3*oi];let value=v[3+3*oi]
        if key<0 or key>1000000:return -1
        let b=Int(key%Int64(bucket_count));var found= -1;var chain=bucket[b]
        while chain>=0:
            if keys[chain]==key:found=chain;break
            chain=next[chain]
        if op==0:
            if value< -1000000 or value>1000000:return -1
            if found>=0:vals[found]=value
            else:
                if size>=64:return -1
                var free= -1
                for i in range(64):if not active[i]:free=i;break
                if free<0:return -1
                active[free]=True;size+=1;keys[free]=key;vals[free]=value;next[free]=bucket[b];bucket[b]=free
                if size*4>bucket_count*3 and bucket_count<128:
                    bucket_count*=2
                    for i in range(bucket_count):bucket[i]= -1
                    for i in range(64):
                        if active[i]:
                            let new_bucket=Int(keys[i]%Int64(bucket_count));next[i]=bucket[new_bucket];bucket[new_bucket]=i
        elif op==1 or op==3:
            if value!=0:return -1
            var observed:Int64=0
            if op==1:observed=vals[found] if found>=0 else -9223372036854775807-1
            else:observed=1 if found>=0 else 0
            hash=gh_hash(hash,observed)
        elif op==2:
            if value!=0:return -1
            if found>=0:
                var prev= -1;var chain=bucket[b]
                while chain>=0:
                    if chain==found:
                        if prev<0:bucket[b]=next[chain]
                        else:next[prev]=next[chain]
                        break
                    prev=chain;chain=next[chain]
                active[found]=False;next[found]= -1;size-=1
        elif op==4:
            if key!=0 or value!=0:return -1
            hash=gh_hash(hash,Int64(size))
        else:return -1
    hash=gh_hash(hash,Int64(size));var used=InlineArray[Bool,64](fill=False)
    for rank in range(size):
        var best= -1
        for i in range(64):
            if active[i] and not used[i] and (best<0 or keys[i]<keys[best]):best=i
        used[best]=True;hash=gh_hash(gh_hash(hash,keys[best]),vals[best])
    return bitcast[Int64](hash)
