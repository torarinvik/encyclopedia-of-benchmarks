from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ii_feed(h0:UInt64,value:Int64)->UInt64:
    var h=h0;let bits=UInt64(value)
    for b in range(8):h=(h^UInt64(UInt8((bits>>(8*b))&255)))*1099511628211
    return h

@export("inverted_index")
fn inverted_index(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>4627:return -1
    let docs=input[0]
    if docs<0 or docs>256:return -1
    var seen=InlineArray[Bool,256](fill=False)
    var heads=InlineArray[Int32,65536](fill=-1)
    var next=InlineArray[Int32,4096](fill=-1);var postingdoc=InlineArray[UInt8,4096](fill=0);var postings=0;var total=0;var cursor=1
    for d in range(Int(docs)):
        if cursor>Int(length) or Int(length)-cursor<2:return -1
        let doc=input[cursor];let wc=input[cursor+1];cursor+=2
        if doc<0 or doc>=256 or wc<1 or wc>256:return -1
        let di=Int(doc);let wcount=Int(wc)
        if seen[di] or wcount>Int(length)-cursor or total>4096-wcount:return -1
        seen[di]=True;total+=wcount
        for _ in range(wcount):
            let word=input[cursor];cursor+=1
            if word<0 or word>65535:return -1
            let wi=Int(word);var edge=Int(heads[wi]);var duplicate=False
            while edge>=0:
                if postingdoc[edge]==UInt8(di):duplicate=True;break
                edge=Int(next[edge])
            if not duplicate:
                if postings>=4096:return -1
                postingdoc[postings]=UInt8(di);next[postings]=heads[wi];heads[wi]=Int32(postings);postings+=1
    if cursor>Int(length) or Int(length)-cursor<2:return -1
    let op=input[cursor];let terms=input[cursor+1];cursor+=2
    if (op!=0 and op!=1) or terms<1 or terms>16 or Int(terms)!=Int(length)-cursor:return -1
    var query=InlineArray[UInt16,16](fill=0)
    for i in range(Int(terms)):
        if input[cursor+i]<0 or input[cursor+i]>65535:return -1
        query[i]=UInt16(input[cursor+i])
    var result=InlineArray[Bool,256](fill=False);var flags=InlineArray[Bool,256](fill=False)
    if op==0:
        for d in range(256):result[d]=seen[d]
    for t in range(Int(terms)):
        for d in range(256):flags[d]=False
        var edge=Int(heads[Int(query[t])])
        while edge>=0:flags[Int(postingdoc[edge])]=True;edge=Int(next[edge])
        for d in range(256):
            if op==0:result[d]=result[d] and flags[d]
            else:result[d]=result[d] or flags[d]
    var count=0
    for d in range(256):
        if result[d]:count+=1
    var h=UInt64(14695981039346656037);h=ii_feed(h,Int64(count))
    for d in range(256):
        if result[d]:h=ii_feed(h,Int64(d))
    return Int64(h&0x7fffffffffffffff)
