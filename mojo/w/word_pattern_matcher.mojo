from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wpm_search(pat:InlineArray[UInt8,8],pn:Int,txt:InlineArray[UInt8,32],tn:Int,pi:Int,ti:Int,inout starts:InlineArray[Int32,128],inout lens:InlineArray[Int32,128],inout used:InlineArray[Bool,128])->Bool:
    if pi==pn or ti==tn:return pi==pn and ti==tn
    let sym=Int(pat[pi])
    if lens[sym]>0:
        let len=Int(lens[sym])
        if ti+len>tn:return False
        for j in range(len):if txt[ti+j]!=txt[Int(starts[sym])+j]:return False
        return wpm_search(pat,pn,txt,tn,pi+1,ti+len,starts,lens,used)
    for end in range(ti+1,tn+1):
        let len=end-ti;var duplicate=false
        for s in range(128):
            if used[s] and lens[s]==len:
                var same=true
                for j in range(len):if txt[ti+j]!=txt[Int(starts[s])+j]:same=false
                if same:duplicate=true
        if duplicate:continue
        starts[sym]=Int32(ti);lens[sym]=Int32(len);used[sym]=True
        if wpm_search(pat,pn,txt,tn,pi+1,end,starts,lens,used):return True
        starts[sym]=0;lens[sym]=0;used[sym]=False
    return False
@export("word_pattern_matcher")
fn word_pattern_matcher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>42:return -1
    let pn=a[0]
    if pn<0 or pn>8 or n<c_size_t(pn+2):return -1
    let ti=Int(pn)+1;let tn=a[ti]
    if tn<0 or tn>32 or n!=c_size_t(ti+1+tn):return -1
    var pat=InlineArray[UInt8,8]();var txt=InlineArray[UInt8,32]()
    for i in range(Int(pn)):if a[i+1]<32 or a[i+1]>126:return -1;else:pat[i]=UInt8(a[i+1])
    for i in range(Int(tn)):if a[ti+1+i]<32 or a[ti+1+i]>126:return -1;else:txt[i]=UInt8(a[ti+1+i])
    var starts=InlineArray[Int32,128]();var lens=InlineArray[Int32,128]();var used=InlineArray[Bool,128]()
    return 1 if wpm_search(pat,Int(pn),txt,Int(tn),0,0,starts,lens,used) else 0
