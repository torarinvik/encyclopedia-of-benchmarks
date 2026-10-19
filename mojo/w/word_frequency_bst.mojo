from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wfb_alpha(c:UInt8)->Bool:return (c>=65 and c<=90) or (c>=97 and c<=122)
fn wfb_compare(tok:InlineArray[UInt8,45],len:Int,words:InlineArray[InlineArray[UInt8,45],128],wl:InlineArray[Int32,128],node:Int)->Int:
    let common=min(len,Int(wl[node]))
    for i in range(common):if tok[i]<words[node][i]:return -1;elif tok[i]>words[node][i]:return 1
    if len<Int(wl[node]):return -1
    if len>Int(wl[node]):return 1
    return 0
fn wfb_insert(tok:InlineArray[UInt8,45],len:Int,inout words:InlineArray[InlineArray[UInt8,45],128],inout wl:InlineArray[Int32,128],inout freq:InlineArray[Int32,128],inout left:InlineArray[Int32,128],inout right:InlineArray[Int32,128],inout used:Int,inout root:Int)->Bool:
    if len==0:return True
    if tok[len-1]==45:len-=1
    if len==0:return True
    if root<0:
        if used>=128:return False
        root=used;words[used]=tok;wl[used]=Int32(len);freq[used]=1;left[used]= -1;right[used]= -1;used+=1;return True
    var current=root
    while True:
        let cmp=wfb_compare(tok,len,words,wl,current)
        if cmp==0:freq[current]+=1;return True
        if cmp<0:
            if left[current]<0:
                if used>=128:return False
                left[current]=Int32(used);words[used]=tok;wl[used]=Int32(len);freq[used]=1;left[used]= -1;right[used]= -1;used+=1;return True
            current=Int(left[current])
        else:
            if right[current]<0:
                if used>=128:return False
                right[current]=Int32(used);words[used]=tok;wl[used]=Int32(len);freq[used]=1;left[used]= -1;right[used]= -1;used+=1;return True
            current=Int(right[current])
@export("word_frequency_bst")
fn word_frequency_bst(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or a[0]<0 or a[0]>256 or n!=c_size_t(a[0]+1):return -1
    let textlen=Int(a[0]);for i in range(textlen):if a[i+1]<0 or a[i+1]>127:return -1
    var words=InlineArray[InlineArray[UInt8,45],128]();var wl=InlineArray[Int32,128]();var freq=InlineArray[Int32,128]();var left=InlineArray[Int32,128]();var right=InlineArray[Int32,128]();var used=0;var root= -1;var tok=InlineArray[UInt8,45]();var tl=0
    for i in range(textlen):
        let c=UInt8(a[i+1])
        if wfb_alpha(c):
            if tl>=45:return -1
            tok[tl]=c+32 if c>=65 and c<=90 else c;tl+=1
        elif (c==39 or c==45) and tl>0 and wfb_alpha(tok[tl-1]):
            if tl>=45:return -1
            tok[tl]=c;tl+=1
        else:
            if not wfb_insert(tok,tl,words,wl,freq,left,right,used,root):return -1
            tok=InlineArray[UInt8,45]();tl=0
    if not wfb_insert(tok,tl,words,wl,freq,left,right,used,root):return -1
    var staged=InlineArray[UInt8,896]();var written=0;var stack=InlineArray[Int32,128]();var top=0;var current=root
    while current>=0 or top>0:
        while current>=0:stack[top]=Int32(current);top+=1;current=Int(left[current])
        top-=1;current=Int(stack[top]);let node=current
        for j in range(Int(wl[node])):staged[written]=words[node][j];written+=1
        staged[written]=9;written+=1
        var x=Int(freq[node]);var digits=InlineArray[UInt8,10]();var dc=0
        while x>0:digits[dc]=UInt8(48+x%10);dc+=1;x/=10
        while dc>0:dc-=1;staged[written]=digits[dc];written+=1
        staged[written]=10;written+=1;current=Int(right[node])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(written):return -2
    for j in range(written):o[j]=staged[j]
    return Int64(written)
