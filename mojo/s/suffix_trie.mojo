from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAXN=2081
fn trie_child(first:UnsafePointer[Int32,MutAnyOrigin],next:UnsafePointer[Int32,MutAnyOrigin],code:UnsafePointer[UInt8,MutAnyOrigin],parent:Int,ch:UInt8)->Int:
    var node=first[parent]
    while node>=0:
        if code[Int(node)]==ch:return Int(node)
        node=next[Int(node)]
    return -1
@export("suffix_trie_search")
fn suffix_trie_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>83:return -1
    let tn=v[0];let pn=v[1]
    if tn<0 or tn>64 or pn<0 or pn>16 or n!=c_size_t(2+tn+pn):return -1
    var text=InlineArray[UInt8,64](fill=0);var pat=InlineArray[UInt8,16](fill=0)
    for i in range(Int(tn)):
        if v[2+i]<0 or v[2+i]>127:return -1
        text[i]=UInt8(v[2+i])
    for i in range(Int(pn)):
        if v[2+Int(tn)+i]<0 or v[2+Int(tn)+i]>127:return -1
        pat[i]=UInt8(v[2+Int(tn)+i])
    var first=InlineArray[Int32,MAXN](fill= -1);var next=InlineArray[Int32,MAXN](fill= -1);var codes=InlineArray[UInt8,MAXN](fill=0);var count=1
    for start in range(Int(tn)):
        var parent=0
        for pos in range(start,Int(tn)):
            var child=trie_child(first.unsafe_ptr(),next.unsafe_ptr(),codes.unsafe_ptr(),parent,text[pos])
            if child<0:
                child=count;count+=1;codes[child]=text[pos];next[child]=first[parent];first[parent]=Int32(child)
            parent=child
    var node=0
    for i in range(Int(pn)):
        let child=trie_child(first.unsafe_ptr(),next.unsafe_ptr(),codes.unsafe_ptr(),node,pat[i])
        if child<0:return 0
        node=child
    return 1
