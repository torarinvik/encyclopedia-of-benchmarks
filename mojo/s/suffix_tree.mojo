from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXTXT=64
comptime MAXNODE=129
comptime MAXEDGE=128
comptime MAXBYTES=5176
comptime NONE= -1
fn tree_write_u64(out:UnsafePointer[UInt8,MutAnyOrigin],pos:UnsafePointer[Int,MutAnyOrigin],value:UInt64):
    for b in range(8):out[pos[0]]=UInt8((value>>UInt(b*8))&255);pos[0]+=1
fn tree_append(parent:Int,child:Int,first:UnsafePointer[Int32,MutAnyOrigin],last:UnsafePointer[Int32,MutAnyOrigin],ec:UnsafePointer[Int32,MutAnyOrigin],en:UnsafePointer[Int32,MutAnyOrigin],edge_count:UnsafePointer[Int,MutAnyOrigin]):
    let e=edge_count[0];edge_count[0]+=1;ec[e]=Int32(child);en[e]= -1
    if last[parent]<0:first[parent]=Int32(e)
    else:en[Int(last[parent])]=Int32(e)
    last[parent]=Int32(e)
@export("suffix_tree_construct")
fn suffix_tree_construct(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    let tn=v[0]
    if tn<0 or tn>MAXTXT or n!=c_size_t(1+tn):return -1
    var text=InlineArray[UInt8,MAXTXT](fill=0)
    for i in range(Int(tn)):
        if v[1+i]<0 or v[1+i]>127:return -1
        text[i]=UInt8(v[1+i])
    var labels=InlineArray[UInt8,MAXNODE*MAXTXT](fill=0);var lens=InlineArray[Int,MAXNODE](fill=0)
    var first=InlineArray[Int32,MAXNODE](fill= -1);var last=InlineArray[Int32,MAXNODE](fill= -1)
    var ec=InlineArray[Int32,MAXEDGE](fill=0);var en=InlineArray[Int32,MAXEDGE](fill= -1)
    var nodes=1;var edge_count=InlineArray[Int,1](fill=0)
    for start in range(Int(tn)):
        let suffix_len=Int(tn)-start;var off=0;var node=0
        while off<suffix_len:
            let code=text[start+off];var selected=first[node]
            while selected>=0 and labels[Int(ec[Int(selected)])*MAXTXT]!=code:selected=en[Int(selected)]
            if selected<0:
                let leaf=nodes;nodes+=1;let llen=suffix_len-off
                for z in range(llen):labels[leaf*MAXTXT+z]=text[start+off+z]
                lens[leaf]=llen;tree_append(node,leaf,first.unsafe_ptr(),last.unsafe_ptr(),ec.unsafe_ptr(),en.unsafe_ptr(),edge_count.unsafe_ptr());break
            let child=Int(ec[Int(selected)]);let clen=lens[child];var common=0
            while common<clen and off+common<suffix_len and labels[child*MAXTXT+common]==text[start+off+common]:common+=1
            if common==clen:off+=common;node=child;continue
            let split=nodes;nodes+=1
            for z in range(common):labels[split*MAXTXT+z]=labels[child*MAXTXT+z]
            lens[split]=common;let rem=clen-common
            for z in range(rem):labels[child*MAXTXT+z]=labels[child*MAXTXT+common+z]
            lens[child]=rem;ec[Int(selected)]=Int32(split)
            tree_append(split,child,first.unsafe_ptr(),last.unsafe_ptr(),ec.unsafe_ptr(),en.unsafe_ptr(),edge_count.unsafe_ptr())
            off+=common;node=split
    var bytes=InlineArray[UInt8,MAXBYTES](fill=0);var pos=InlineArray[Int,1](fill=0)
    tree_write_u64(bytes.unsafe_ptr(),pos.unsafe_ptr(),UInt64(nodes))
    for node in range(nodes):
        tree_write_u64(bytes.unsafe_ptr(),pos.unsafe_ptr(),UInt64(lens[node]))
        for z in range(lens[node]):bytes[pos[0]]=labels[node*MAXTXT+z];pos[0]+=1
        var child_count=0;var edge=first[node]
        while edge>=0:child_count+=1;edge=en[Int(edge)]
        tree_write_u64(bytes.unsafe_ptr(),pos.unsafe_ptr(),UInt64(child_count));edge=first[node]
        while edge>=0:tree_write_u64(bytes.unsafe_ptr(),pos.unsafe_ptr(),UInt64(ec[Int(edge)]));edge=en[Int(edge)]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos[0]):return -2
    for i in range(pos[0]):out[i]=bytes[i]
    return pos[0]
