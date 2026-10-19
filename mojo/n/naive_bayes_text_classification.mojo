from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, log
fn nb_token(a:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,len:Int)->Int64:
    var code:Int64=0
    for i in range(len):
        var ch=a[start+i]
        if ch>=65 and ch<=90:ch+=32
        if not ((ch>=97 and ch<=122) or (ch>=48 and ch<=57) or ch==39):return -1
        code=code*128+ch
    return code
fn nb_put_f64(o:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):o[offset+b]=UInt8((bits>>(8*b))&255)
@export("naive_bayes_text_classification")
fn naive_bayes_text_classification(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>71 or a[0]<2 or a[0]>6 or a[1]<1 or a[1]>10000:return -1
    let docs=Int(a[0]);let alpha=Float64(a[1])/1000.0;var words=InlineArray[Int64,6]();var labs=InlineArray[Int64,6]();var seen=InlineArray[Bool,2]();var totals=InlineArray[Int64,2]();var pos=2
    for i in range(docs):
        if pos+2>Int(n):return -1
        let lab=a[pos];let len=a[pos+1];pos+=2
        if lab<0 or lab>1 or len<0 or len>8 or pos+Int(len)>Int(n):return -1
        let word=nb_token(a,pos,Int(len));if word<0:return -1
        labs[i]=lab;words[i]=word;seen[Int(lab)]=True;if len>0:totals[Int(lab)]+=1;pos+=Int(len)
    if pos>=Int(n) or not seen[0] or not seen[1]:return -1
    let qlen=a[pos];pos+=1
    if qlen<0 or qlen>8 or pos+Int(qlen)!=Int(n):return -1
    let query=nb_token(a,pos,Int(qlen));if query<0:return -1
    var vocab=0
    for i in range(docs):if words[i]!=0:
        var first=True
        for j in range(i):if words[j]==words[i]:first=False
        if first:vocab+=1
    if vocab==0 and qlen>0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    var known=False
    for i in range(docs):if words[i]==query and query!=0:known=True
    var score=InlineArray[Float64,2]()
    for c in range(2):
        var dc=0;var wc=0
        for i in range(docs):if labs[i]==c:dc+=1;if qlen>0 and words[i]==query:wc+=1
        score[c]=log(Float64(dc)/Float64(docs))
        if known:score[c]+=log((Float64(wc)+alpha)/(Float64(totals[c])+alpha*Float64(vocab)))
    let hi=max(score[0],score[1]);let p0=exp(score[0]-hi);let p1=exp(score[1]-hi);let denom=p0+p1
    nb_put_f64(o,0,p0/denom);nb_put_f64(o,8,p1/denom);return 16
