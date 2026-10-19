from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime NIL=256
@export("linked_list_benchmark")
fn linked_list_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or n%2!=0 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let opcount=Int(n)/2
    var values=InlineArray[Int64,256](fill=0);var next=InlineArray[Int64,256](fill=0)
    for i in range(256):next[i]=Int64(i+1)
    var freehead=0;var head=NIL;var tail=NIL;var count=0;var checksum:Int64=0
    for oi in range(opcount):
        let op=v[2*oi];let payload=v[2*oi+1];var observed:Int64=0;var returns=True
        if op==0 or op==1:
            if payload < -1000000 or payload>1000000 or count==256 or freehead==NIL:return -1
            let node=freehead;freehead=Int(next[node]);values[node]=payload
            if op==0:
                if tail==NIL:head=node
                else:next[tail]=Int64(node)
                tail=node;next[node]=NIL
            else:
                next[node]=Int64(head);head=node
                if tail==NIL:tail=node
            count+=1;returns=False
        elif op==2:
            if payload!=0 or count==0:return -1
            let node=head;observed=values[node];head=Int(next[node])
            if head==NIL:tail=NIL
            next[node]=Int64(freehead);freehead=node;count-=1
        elif op==3:
            if payload!=0 or count==0:return -1
            let node=tail;observed=values[node]
            if head==tail:head=NIL;tail=NIL
            else:
                var before=head
                while next[before]!=tail:before=Int(next[before])
                tail=before;next[before]=NIL
            next[node]=Int64(freehead);freehead=node;count-=1
        elif op==4 or op==5:
            if payload < -1000000 or payload>1000000:return -1
            var before=NIL;var node=head
            while node!=NIL and values[node]!=payload:before=node;node=Int(next[node])
            observed=Int64(node!=NIL)
            if op==4 and node!=NIL:
                if before==NIL:head=Int(next[node])
                else:next[before]=next[node]
                if tail==node:tail=before
                next[node]=Int64(freehead);freehead=node;count-=1
        elif op==6:
            if payload!=0:return -1
            observed=Int64(count)
        elif op==7:
            if payload!=0:return -1
            var previous=NIL;var node=head;tail=head
            while node!=NIL:
                let nx=Int(next[node]);next[node]=Int64(previous);previous=node;node=nx
            head=previous;returns=False
        else:return -1
        if returns:checksum+=(Int64(oi)+1)*(observed+1000000)
    var node=head;var index=0
    while node!=NIL:
        checksum+=(Int64(opcount+index)+1)*(values[node]+1000000);node=Int(next[node]);index+=1
    return checksum
