from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("text_justification")
fn text_justification(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>515:return -1
    let width0=a[0];let len0=a[1]
    if width0<1 or width0>64 or len0<0 or len0>512 or n!=c_size_t(len0+2):return -1
    let width=Int(width0);let textn=Int(len0)
    var starts=InlineArray[Int,64]();var lens=InlineArray[Int,64]();var count=0;var i=0
    for k in range(textn):
        let x=a[k+2]
        if x!=32 and (x<33 or x>126):return -1
    while i<textn:
        while i<textn and a[i+2]==32:i+=1
        if i>=textn:break
        let start=i
        while i<textn and a[i+2]!=32:i+=1
        let l=i-start
        if count>=64 or l>width:return -1
        starts[count]=start;lens[count]=l;count+=1
    var result=InlineArray[UInt8,4160]();var outn=0;var ls=0;var le=0;var letters=0;var first_line=True
    for word in range(count):
        if letters+lens[word]+(le-ls)<=width:
            letters+=lens[word];le+=1;continue
        if not first_line:result[outn]=10;outn+=1
        first_line=False
        let words=le-ls
        if words==1:
            for j in range(lens[ls]):result[outn]=UInt8(a[starts[ls]+j+2]);outn+=1
            for _ in range(lens[ls],width):result[outn]=32;outn+=1
        else:
            let gaps=words-1;let spaces=width-letters;let base=spaces/gaps;let extra=spaces%gaps
            for item in range(words):
                let ix=ls+item
                for j in range(lens[ix]):result[outn]=UInt8(a[starts[ix]+j+2]);outn+=1
                if item+1<words:
                    let gap=base+(1 if item<extra else 0)
                    for _ in range(gap):result[outn]=32;outn+=1
        ls=word;le=word+1;letters=lens[word]
    if not first_line:result[outn]=10;outn+=1
    for item in range(ls,le):
        if item!=ls:result[outn]=32;outn+=1
        for j in range(lens[item]):result[outn]=UInt8(a[starts[item]+j+2]);outn+=1
    let trailing=width-letters-(le-ls)+1
    for _ in range(trailing):result[outn]=32;outn+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    for j in range(outn):o[j]=result[j]
    return Int64(outn)
