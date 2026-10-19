from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor, isfinite, log10
fn wff_punct(c:Int64)->Bool:
    return (c>=33 and c<=47) or (c>=58 and c<=64) or (c>=91 and c<=96) or (c>=123 and c<=126)
fn wff_lower(c:Int64)->Int64:return c+32 if c>=65 and c<=90 else c
fn wff_round_milli(x:Float64)->Int64:
    let scaled=x*1000.0;let base=floor(scaled);let frac=scaled-base;var q=Int64(base)
    if frac>0.5:q+=1
    elif frac==0.5 and q%2!=0:q+=1
    return q
fn wff_put_i64(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int64):
    let bits=bitcast[UInt64](v)
    for b in range(8):o[at+b]=UInt8((bits>>UInt(8*b))&255)
fn wff_tag(o:UnsafePointer[UInt8,MutAnyOrigin],tag:Int):
    for b in range(4):o[b]=UInt8((tag>> (8*b))&255)
@export("word_frequency_functions")
fn word_frequency_functions(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4227:return -1
    let op=a[0];var tag=0;var payload=InlineArray[Int64,2]();var fields=1
    if op==0 or op==1:
        if n<3:return -1
        let termlen=a[1]
        if termlen<0 or termlen>128:return -1
        let ti=2+Int(termlen)
        if ti>=Int(n) or a[ti]<0 or a[ti]>4096 or n!=c_size_t(ti+1+Int(a[ti])):return -1
        let textlen=Int(a[ti])
        for i in range(Int(termlen)):if a[2+i]<0 or a[2+i]>127:return -1
        for i in range(textlen):if a[ti+1+i]<0 or a[ti+1+i]>127:return -1
        if op==0:
            var clean=InlineArray[UInt8,4096]();var clen=0
            for i in range(textlen):
                let c=a[ti+1+i]
                if not wff_punct(c) and c!=10:clean[clen]=UInt8(c);clen+=1
            var matches=0;var start=0
            for end in range(clen+1):
                if end==clen or clean[end]==32:
                    let len=end-start
                    if len==termlen:
                        var same=true
                        for j in range(len):if Int64(clean[start+j])!=wff_lower(a[2+j]):same=false
                        if same:matches+=1
                    start=end+1
            payload[0]=Int64(matches);tag=0
        else:
            var docs=1;var matches=0;var start=0;var line=InlineArray[UInt8,4096]();var llen=0
            for i in range(textlen+1):
                if i==textlen or a[ti+1+i]==10:
                    var found=termlen==0
                    if not found and Int(termlen)<=llen:
                        for j in range(llen-Int(termlen)+1):
                            var same=true
                            for k in range(Int(termlen)):if line[j+k]!=UInt8(wff_lower(a[2+k])):same=false
                            if same:found=true
                    if found:matches+=1
                    if i<textlen:docs+=1
                    llen=0
                else:
                    let c=a[ti+1+i]
                    if not wff_punct(c):line[llen]=UInt8(wff_lower(c));llen+=1
            payload[0]=Int64(matches);payload[1]=Int64(docs);tag=1;fields=2
    elif op==2:
        if n!=4:return -1
        let df=a[1];let total=a[2];let smooth=a[3]
        if df<0 or df>1000000 or total<0 or total>1000000 or (smooth!=0 and smooth!=1):return -1
        if total==0:tag=4;fields=0
        elif smooth==0 and df==0:tag=3;fields=0
        elif smooth==0 and df>total:return -1
        else:
            var value:Float64
            if smooth==0:value=log10(Float64(total)/Float64(df))
            else:value=1.0+log10(Float64(total)/Float64(df+1))
            if not isfinite(value):return -1
            payload[0]=wff_round_milli(value);tag=2
    elif op==3:
        if n!=3 or a[1]<0 or a[1]>1000000 or a[2]< -1000000 or a[2]>1000000:return -1
        payload[0]=a[1]*a[2];tag=2
    else:return -1
    let needed=4+fields*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    wff_tag(o,tag)
    for i in range(fields):wff_put_i64(o,4+i*8,payload[i])
    return Int64(needed)
