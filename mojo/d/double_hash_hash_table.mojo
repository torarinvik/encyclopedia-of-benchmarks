from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn dht_prime(n:Int)->Bool:
    if n<2:return false
    var d=2
    while d*d<=n:
        if n%d==0:return false
        d+=1
    return true
@export("double_hash_hash_table")
fn double_hash_hash_table(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let capv=input[0];let countv=input[1]
    if capv<3 or capv>101 or not dht_prime(Int(capv)) or countv<0 or countv>512 or length!=c_size_t(2+2*countv):return -1
    let cap=Int(capv);var state=List[Int](length=101,fill=0);var keys=List[Int64](length=101,fill=0);var successes:Int64=0
    for i in range(Int(countv)):
        let op=input[2+2*i];let key=input[3+2*i]
        if op<1 or op>3:return -1
        var first=Int((key%capv+capv)%capv);var step=Int(1+(key%(capv-1)+capv-1)%(capv-1))
        if op==1:
            var tomb=cap;var inserted=false
            for p in range(cap):
                let slot=(first+p*step)%cap
                if state[slot]==1 and keys[slot]==key:tomb=cap;break
                if state[slot]==2 and tomb==cap:tomb=slot
                if state[slot]==0:
                    let target=tomb if tomb!=cap else slot;state[target]=1;keys[target]=key;inserted=true;break
            if not inserted and tomb!=cap:state[tomb]=1;keys[tomb]=key;inserted=true
            if inserted:successes+=1
        else:
            for p in range(cap):
                let slot=(first+p*step)%cap
                if state[slot]==0:break
                if state[slot]==1 and keys[slot]==key:
                    successes+=1
                    if op==3:state[slot]=2
                    break
    return successes
