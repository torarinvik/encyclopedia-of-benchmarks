# Independent bounded maximal exact-match query; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mummer_suffix_less(reference: InlineArray[Int,32], size: Int, left: Int, right: Int) -> Bool:
    var a=left; var b=right
    while a<size and b<size and reference[a]==reference[b]: a+=1; b+=1
    if a==size: return False
    if b==size: return True
    return reference[a]<reference[b]

@export("rodinia_mummergpu")
fn rodinia_mummergpu(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5 or length>67: return -1
    let rv=input[0]; let qv=input[1]; let mv=input[2]
    if rv<1 or rv>32 or qv<1 or qv>32 or mv<1 or mv>32: return -1
    let nr=Int(rv); let nq=Int(qv); let minimum=Int(mv)
    if length!=c_size_t(3+nr+nq): return -1
    var reference=InlineArray[Int,32](fill=0); var query=InlineArray[Int,32](fill=0)
    for i in range(nr):
        if input[3+i]<0 or input[3+i]>3: return -1
        reference[i]=Int(input[3+i])
    for i in range(nq):
        if input[3+nr+i]<0 or input[3+nr+i]>3: return -1
        query[i]=Int(input[3+nr+i])
    # Five children per node: DNA symbols in order, followed by terminator.
    var children=InlineArray[Int,2805](fill=-1)
    var paths=InlineArray[Int,1056](fill=-1)
    var order=InlineArray[Int,32](fill=0)
    var node_count=1
    for start in range(nr):
        var node=0; var depth=0; paths[33*start]=0
        for pos in range(start,nr):
            let slot=5*node+reference[pos]
            if children[slot]<0:
                if node_count>=561: return -1
                children[slot]=node_count; node_count+=1
            node=children[slot]; depth+=1
            paths[33*start+depth]=node
        let terminal=5*node+4
        if children[terminal]<0:
            if node_count>=561: return -1
            children[terminal]=node_count; node_count+=1
        order[start]=start
    for i in range(1,nr):
        let entry=order[i]; var j=i
        while j>0 and mummer_suffix_less(reference,nr,entry,order[j-1]):
            order[j]=order[j-1]; j-=1
        order[j]=entry
    var records=InlineArray[Int64,3072](fill=0); var matches=0
    for qs in range(nq):
        var found=InlineArray[Int,32](fill=-1)
        var node=0; var depth=0
        while True:
            let has_next=qs+depth<nq
            for rs in range(nr):
                if paths[33*rs+depth]!=node: continue
                if rs+depth==nr or not has_next or reference[rs+depth]!=query[qs+depth]: found[rs]=depth
            if not has_next: break
            let child=children[5*node+query[qs+depth]]
            if child<0: break
            node=child; depth+=1
        for i in range(nr):
            let rs=order[i]; let matched=found[rs]
            if matched<minimum: continue
            if qs>0 and rs>0 and query[qs-1]==reference[rs-1]: continue
            records[3*matches]=Int64(rs+1); records[3*matches+1]=Int64(qs+1)
            records[3*matches+2]=Int64(matched); matches+=1
    let bytes=24*matches
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    for i in range(3*matches):
        let bits=bitcast[UInt64](records[i])
        for b in range(8): output[8*i+b]=UInt8((bits >> UInt(8*b)) & UInt64(255))
    return Int64(bytes)
