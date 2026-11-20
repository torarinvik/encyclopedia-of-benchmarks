from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for b in range(8): out[offset+b] = UInt8((bits >> (8*b)) & 255)

@export("two_left_hashing_operation_trace")
fn two_left_hashing_operation_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 162: return -1
    let q0=input[0]
    if q0 < 1 or q0 > 40 or length != c_size_t(1+4*q0): return -1
    let q=Int(q0)
    for i in range(q):
        let op=input[1+4*i];let key=input[2+4*i];let left=input[3+4*i];let right=input[4+4*i]
        if op < 0 or op > 2 or key < 0 or key > 63 or left < 0 or left > 7 or right < 0 or right > 7: return -1
        for j in range(i):
            if input[2+4*j] == key and (input[3+4*j] != left or input[4+4*j] != right): return -1
    let bytes=16*q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var heads=InlineArray[Int32,16]();var sizes=InlineArray[Int32,16]()
    var keys=InlineArray[Int64,32]();var next=InlineArray[Int32,32]()
    var statuses=InlineArray[Int64,40]();var places=InlineArray[Int64,40]()
    for b in range(16): heads[b]= -1
    for x in range(32): keys[x]= -1;next[x]= -1
    var live=0
    for i in range(q):
        let op=input[1+4*i];let key=input[2+4*i];let lb=Int(input[3+4*i]);let rb=8+Int(input[4+4*i])
        var found:Int32= -1;var fb=0
        for side in range(2):
            let bucket=lb if side==0 else rb
            var x=heads[bucket]
            while x >= 0:
                if keys[Int(x)] == key: found=x;fb=bucket;break
                x=next[Int(x)]
            if found >= 0: break
        if op == 0:
            if found >= 0: statuses[i]=0;places[i]= -1;continue
            if live == 32: return -3
            let use_left=sizes[lb] <= sizes[rb];let bucket=lb if use_left else rb
            var node=0
            while keys[node] >= 0: node+=1
            keys[node]=key;next[node]=heads[bucket];heads[bucket]=Int32(node);sizes[bucket]+=1;live+=1
            statuses[i]=1;places[i]=0 if use_left else 1
        elif op == 1:
            statuses[i]=1 if found >= 0 else 0;places[i]= -1
        elif found < 0:
            statuses[i]=0;places[i]= -1
        else:
            var previous:Int32= -1;var x=heads[fb]
            while x != found: previous=x;x=next[Int(x)]
            if previous < 0: heads[fb]=next[Int(x)]
            else: next[Int(previous)]=next[Int(x)]
            keys[Int(x)]= -1;next[Int(x)]= -1;sizes[fb]-=1;live-=1;statuses[i]=1;places[i]= -1
    for i in range(q): put(output,16*i,statuses[i]);put(output,16*i+8,places[i])
    return Int64(bytes)
