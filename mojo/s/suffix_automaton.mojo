from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAX_TEXT=256
comptime MAX_STATES=512
comptime ALPHA=128
fn sam_find(next:UnsafePointer[Int32,MutAnyOrigin],pattern:UnsafePointer[UInt8,MutAnyOrigin],plen:Int)->Int:
    var state=0
    for i in range(plen):
        let target=next[state*ALPHA+Int(pattern[i])]
        if target<0:return -1
        state=Int(target)
    return state
fn sam_occurrences(next:UnsafePointer[Int32,MutAnyOrigin],links:UnsafePointer[Int32,MutAnyOrigin],lens:UnsafePointer[Int32,MutAnyOrigin],state_count:Int,text:UnsafePointer[UInt8,MutAnyOrigin],tn:Int,pattern:UnsafePointer[UInt8,MutAnyOrigin],plen:Int)->Int64:
    let found=sam_find(next,pattern,plen)
    if found<0:return 0
    var occ=InlineArray[Int64,MAX_STATES](fill=0);var counts=InlineArray[Int,MAX_TEXT+1](fill=0);var order=InlineArray[Int,MAX_STATES](fill=0)
    for s in range(state_count):counts[Int(lens[s])]+=1
    for l in range(1,tn+1):counts[l]+=counts[l-1]
    for si in range(state_count):
        let s=state_count-1-si;let l=Int(lens[s]);counts[l]-=1;order[counts[l]]=s
    var last=0
    for i in range(tn):last=Int(next[last*ALPHA+Int(text[i])]);occ[last]=1
    for ri in range(state_count):
        let s=order[state_count-1-ri];let link=links[s]
        if link>=0:occ[Int(link)]+=occ[s]
    return occ[found]
fn sam_distinct(links:UnsafePointer[Int32,MutAnyOrigin],lens:UnsafePointer[Int32,MutAnyOrigin],state_count:Int)->Int64:
    var total:Int64=0
    for s in range(1,state_count):total+=Int64(lens[s]-lens[Int(links[s])])
    return total
@export("suffix_automaton")
fn suffix_automaton(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33283:return -1
    let tn64=v[0]
    if tn64<1 or tn64>MAX_TEXT:return -1
    let tn=Int(tn64);let qi=tn+1
    if n<=c_size_t(qi) or v[qi]<0 or v[qi]>128:return -1
    let qn=Int(v[qi]);if n>33282:return -1
    var text=InlineArray[UInt8,MAX_TEXT](fill=0)
    for i in range(tn):if v[1+i]<0 or v[1+i]>127:return -1
    for i in range(tn):text[i]=UInt8(v[1+i])
    var next=InlineArray[Int32,MAX_STATES*ALPHA](fill= -1);var links=InlineArray[Int32,MAX_STATES](fill= -1);var lens=InlineArray[Int32,MAX_STATES](fill=0)
    var states=1;var last=0
    for i in range(tn):
        let symbol=Int(text[i]);let cur=states;states+=1;lens[cur]=lens[last]+1
        var p=last
        while p>=0 and next[p*ALPHA+symbol]<0:
            next[p*ALPHA+symbol]=Int32(cur);p=Int(links[p])
        if p<0:links[cur]=0
        else:
            let q=Int(next[p*ALPHA+symbol])
            if lens[p]+1==lens[q]:links[cur]=Int32(q)
            else:
                let clone=states;states+=1;lens[clone]=lens[p]+1;links[clone]=links[q]
                for a in range(ALPHA):next[clone*ALPHA+a]=next[q*ALPHA+a]
                while p>=0 and next[p*ALPHA+symbol]==q:
                    next[p*ALPHA+symbol]=Int32(clone);p=Int(links[p])
                links[q]=Int32(clone);links[cur]=Int32(clone)
        last=cur
    var results=InlineArray[Int64,128](fill=0);var ops=InlineArray[UInt8,128](fill=0);var cursor=qi+1
    for qindex in range(qn):
        if cursor+1>=Int(n):return -1
        let opcode=v[cursor];cursor+=1;let plen64=v[cursor];cursor+=1
        if opcode<0 or opcode>2 or plen64<0 or plen64>256:return -1
        let plen=Int(plen64)
        if opcode==2 and plen!=0:return -1
        if plen>Int(n)-cursor:return -1
        var pat=InlineArray[UInt8,MAX_TEXT](fill=0)
        for i in range(plen):
            let code=v[cursor];cursor+=1
            if code<0 or code>127:return -1
            pat[i]=UInt8(code)
        ops[qindex]=UInt8(opcode)
        if opcode==0:results[qindex]=1 if sam_find(next.unsafe_ptr(),pat.unsafe_ptr(),plen)>=0 else 0
        elif opcode==1:results[qindex]=sam_occurrences(next.unsafe_ptr(),links.unsafe_ptr(),lens.unsafe_ptr(),states,text.unsafe_ptr(),tn,pat.unsafe_ptr(),plen)
        else:results[qindex]=sam_distinct(links.unsafe_ptr(),lens.unsafe_ptr(),states)
    if cursor!=Int(n):return -1
    let outbytes=qn*9
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outbytes):return -2
    var staged=InlineArray[UInt8,1152](fill=0)
    for qindex in range(qn):
        staged[qindex*9]=ops[qindex];let bits=bitcast[UInt64](results[qindex])
        for b in range(8):staged[qindex*9+1+b]=UInt8((bits>>UInt(b*8))&255)
    for i in range(outbytes):out[i]=staged[i]
    return outbytes
