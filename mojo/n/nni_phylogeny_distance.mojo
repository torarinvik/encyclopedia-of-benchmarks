# Exact bounded NNI topology distance; see the package README for provenance.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn nni_bits(value: Int, n: Int) -> Int:
    var count=0
    for i in range(n): count+=(value >> i) & 1
    return count

fn nni_valid(input: UnsafePointer[Int64,ImmutAnyOrigin], offset: Int, n: Int, edges: Int) -> Bool:
    let universe=(1 << n)-1
    var splits=InlineArray[Int,11](fill=0)
    var internal=InlineArray[Int,11](fill=0)
    var count=0
    for i in range(edges):
        let raw=input[offset+i]
        if raw<=0 or raw>=Int64(universe) or (raw & 1)!=0: return False
        let s=Int(raw)
        for j in range(i):
            if splits[j]==s: return False
        splits[i]=s
        let size=nni_bits(s,n)
        if size==1 or size==n-1:
            if size==n-1 and s!=(universe ^ 1): return False
        elif size>=2 and size<=n-2:
            internal[count]=s; count+=1
        else: return False
    if count!=n-3: return False
    for leaf in range(1,n):
        var found=False
        for i in range(edges):
            if splits[i]==(1 << leaf): found=True
        if not found: return False
    var root=False
    for i in range(edges):
        if splits[i]==(universe ^ 1): root=True
    if not root: return False
    for i in range(count):
        for j in range(i+1,count):
            let common=internal[i] & internal[j]
            if common!=0 and common!=internal[i] and common!=internal[j]: return False
    return True

fn nni_sort(mut state: InlineArray[Int,11], edges: Int):
    for i in range(1,edges):
        let value=state[i]
        var j=i
        while j>0 and state[j-1]>value:
            state[j]=state[j-1]; j-=1
        state[j]=value

fn nni_matches(states: InlineArray[Int,10395], index: Int, candidate: InlineArray[Int,11], edges: Int) -> Bool:
    for i in range(edges):
        if states[index*11+i]!=candidate[i]: return False
    return True

@export("nni_phylogeny_distance")
fn nni_phylogeny_distance(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<7 or length>23: return -1
    if input[0]<3 or input[0]>7: return -1
    let n=Int(input[0]); let edges=2*n-3
    if length!=c_size_t(1+2*edges) or not nni_valid(input,1,n,edges) or not nni_valid(input,1+edges,n,edges): return -1
    var states=InlineArray[Int,10395](fill=0)
    var following=InlineArray[Int,10395](fill=0)
    states[0]=2; states[1]=4; states[2]=6
    var state_count=1; var old_edges=3
    for size in range(4,n+1):
        let new_edges=old_edges+2; let new_bit=1 << (size-1)
        var next_count=0
        for s in range(state_count):
            for selected_index in range(old_edges):
                let selected=states[s*11+selected_index]
                var candidate=InlineArray[Int,11](fill=0)
                var used=0
                for i in range(old_edges):
                    let split=states[s*11+i]
                    if split==selected:
                        candidate[used]=split; candidate[used+1]=split | new_bit; used+=2
                    elif (selected & split)==selected:
                        candidate[used]=split | new_bit; used+=1
                    else:
                        candidate[used]=split; used+=1
                candidate[used]=new_bit; used+=1
                nni_sort(candidate,used)
                var present=False
                for i in range(next_count):
                    if nni_matches(following,i,candidate,new_edges): present=True; break
                if not present:
                    if next_count>=945: return -1
                    for i in range(new_edges): following[next_count*11+i]=candidate[i]
                    next_count+=1
        for i in range(next_count*11): states[i]=following[i]
        state_count=next_count; old_edges=new_edges
    var start=InlineArray[Int,11](fill=0); var goal=InlineArray[Int,11](fill=0)
    for i in range(edges): start[i]=Int(input[1+i]); goal[i]=Int(input[1+edges+i])
    nni_sort(start,edges); nni_sort(goal,edges)
    var first = -1; var last = -1
    for i in range(state_count):
        if nni_matches(states,i,start,edges): first=i
        if nni_matches(states,i,goal,edges): last=i
    if first<0 or last<0: return -1
    var neighbors=InlineArray[Int,7560](fill=0)
    var degree=InlineArray[Int,945](fill=0)
    for left in range(state_count):
        for right in range(left+1,state_count):
            var common=0
            for i in range(edges):
                let split=states[left*11+i]; let size=nni_bits(split,n)
                if size<2 or size>n-2: continue
                for j in range(edges):
                    if states[right*11+j]==split: common+=1; break
            if common+n==edges-1:
                if degree[left]>=8 or degree[right]>=8: return -1
                neighbors[left*8+degree[left]]=right; degree[left]+=1
                neighbors[right*8+degree[right]]=left; degree[right]+=1
    var distance=InlineArray[Int,945](fill=-1)
    var queue=InlineArray[Int,945](fill=0)
    var head=0; var tail=1
    distance[first]=0; queue[0]=first
    while head<tail:
        let current=queue[head]; head+=1
        if current==last: break
        for i in range(degree[current]):
            let next=neighbors[current*8+i]
            if distance[next]<0:
                distance[next]=distance[current]+1
                queue[tail]=next; tail+=1
    if distance[last]<0: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<8: return -2
    let bits=UInt64(distance[last])
    for byte in range(8): output[byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return 8
