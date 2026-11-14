# Independent Hopcroft partition-refinement draft; uncompiled and unrun.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn hdm_enqueue(id: Int, mut queued: List[Int], mut queue: List[Int], tail: Int) -> Int:
    if queued[id]!=0: return tail
    queued[id]=1
    queue[tail]=id
    return (tail+1)%len(queue)

@export("hopcroft_dfa_minimization")
fn hopcroft_dfa_minimization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2: return -1
    if input[0]<1 or input[0]>4096 or input[1]<1 or input[1]>4: return -1
    let n=Int(input[0])
    let k=Int(input[1])
    if length!=c_size_t(2+n*(k+1)): return -1
    for state in range(n):
        if input[2+state]!=0 and input[2+state]!=1: return -1
    for i in range(n*k):
        if input[2+n+i]<0 or input[2+n+i]>=Int64(n): return -1
    let nk=n*k
    var reverse_head=List[Int](length=nk,fill=-1)
    var reverse_next=List[Int](length=nk,fill=0)
    var queued=List[Int](length=nk,fill=0)
    var queue=List[Int](length=nk+1,fill=0)
    var block_head=List[Int](length=n,fill=-1)
    var block_size=List[Int](length=n,fill=0)
    var block_of=List[Int](length=n,fill=0)
    var previous=List[Int](length=n,fill=0)
    var following=List[Int](length=n,fill=0)
    var selected_head=List[Int](length=n,fill=-1)
    var selected_next=List[Int](length=n,fill=0)
    var selected_count=List[Int](length=n,fill=0)
    var touched=List[Int](length=n,fill=0)
    for state in range(n):
        for symbol in range(k):
            let edge=state*k+symbol
            let destination=Int(input[2+n+edge])
            reverse_next[edge]=reverse_head[symbol*n+destination]
            reverse_head[symbol*n+destination]=edge
    var has_zero=False
    var has_one=False
    for state in range(n):
        if input[2+state]==0: has_zero=True
        else: has_one=True
    var block_count=0
    if has_zero: block_count+=1
    if has_one: block_count+=1
    for state in range(n):
        var block=0
        if has_zero and input[2+state]==1: block=1
        block_of[state]=block
        previous[state]=-1
        following[state]=block_head[block]
        if following[state]!=-1: previous[following[state]]=state
        block_head[block]=state
        block_size[block]+=1
    var qhead=0
    var qtail=0
    for block in range(block_count):
        for symbol in range(k): qtail=hdm_enqueue(block*k+symbol,queued,queue,qtail)
    while qhead!=qtail:
        let id=queue[qhead]
        qhead=(qhead+1)%len(queue)
        queued[id]=0
        let splitter=id//k
        let symbol=id%k
        var touched_count=0
        var dest=block_head[splitter]
        while dest!=-1:
            var edge=reverse_head[symbol*n+dest]
            while edge!=-1:
                let state=edge//k
                let block=block_of[state]
                if selected_count[block]==0:
                    touched[touched_count]=block
                    touched_count+=1
                selected_count[block]+=1
                selected_next[state]=selected_head[block]
                selected_head[block]=state
                edge=reverse_next[edge]
            dest=following[dest]
        for i in range(touched_count):
            let block=touched[i]
            if selected_count[block]==block_size[block]:
                selected_count[block]=0
                selected_head[block]=-1
                continue
            let fresh=block_count
            block_count+=1
            var state=selected_head[block]
            while state!=-1:
                let after=selected_next[state]
                let prev=previous[state]
                let next=following[state]
                if prev==-1: block_head[block]=next
                else: following[prev]=next
                if next!=-1: previous[next]=prev
                block_size[block]-=1
                previous[state]=-1
                following[state]=block_head[fresh]
                if following[state]!=-1: previous[following[state]]=state
                block_head[fresh]=state
                block_size[fresh]+=1
                block_of[state]=fresh
                state=after
            selected_head[block]=-1
            selected_count[block]=0
            for c in range(k):
                if queued[block*k+c]!=0:
                    qtail=hdm_enqueue(fresh*k+c,queued,queue,qtail)
                else:
                    var smaller=block
                    if block_size[fresh]<block_size[block]: smaller=fresh
                    qtail=hdm_enqueue(smaller*k+c,queued,queue,qtail)
    return Int64(block_count)
