from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("doubly_linked_list_benchmark")
fn doubly_linked_list_benchmark(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>1024 or length%2!=0 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var nodeval=List[Int64](length=256,fill=0);var next=List[Int](length=256,fill=0);var prev=List[Int](length=256,fill=256)
    for i in range(256):next[i]=i+1
    var freehead=0;var head=256;var tail=256;var count=0;var checksum:Int64=0;let ops=Int(length)/2
    for opi in range(ops):
        let op=values[2*opi];let payload=values[2*opi+1];var observed:Int64=0;var returns=true
        if op==0 or op==1:
            if payload< -1000000 or payload>1000000 or count==256 or freehead==256:return -1
            let node=freehead;freehead=next[node];nodeval[node]=payload;next[node]=256;prev[node]=256
            if op==0:
                if tail==256:head=node
                else:prev[node]=tail;next[tail]=node
                tail=node
            else:
                if head==256:tail=node
                else:next[node]=head;prev[head]=node
                head=node
            count+=1;returns=false
        elif op==2 or op==3:
            if payload!=0 or count==0:return -1
            let node=head if op==2 else tail;observed=nodeval[node];let before=prev[node];let after=next[node]
            if before==256:head=after
            else:next[before]=after
            if after==256:tail=before
            else:prev[after]=before
            next[node]=freehead;freehead=node;count-=1
        elif op==4 or op==5:
            if payload< -1000000 or payload>1000000:return -1
            var node=head
            while node!=256 and nodeval[node]!=payload:node=next[node]
            observed=1 if node!=256 else 0
            if op==4 and node!=256:
                let before=prev[node];let after=next[node]
                if before==256:head=after
                else:next[before]=after
                if after==256:tail=before
                else:prev[after]=before
                next[node]=freehead;freehead=node;count-=1
        elif op==6:
            if payload!=0:return -1
            observed=Int64(count)
        else:return -1
        if returns:checksum+=(Int64(opi)+1)*(observed+1000000)
    var node=head;var index=0
    while node!=256:checksum+=(Int64(ops+index)+1)*(nodeval[node]+1000000);node=next[node];index+=1
    node=tail;index=0
    while node!=256:checksum+=(Int64(ops+count+index)+1)*(nodeval[node]+1000000);node=prev[node];index+=1
    return checksum
