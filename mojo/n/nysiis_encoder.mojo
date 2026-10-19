from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ny_match(s:InlineArray[UInt8,64],length:Int,at:Int,word:String)->Bool:
    let bytes=word.as_bytes()
    if at+len(bytes)>length:return False
    for i in range(len(bytes)):if s[at+i]!=bytes[i]:return False
    return True
fn ny_replace(mut s:InlineArray[UInt8,64],mut length:Int,at:Int,from:String,to:String):
    let f=from.as_bytes();let t=to.as_bytes();let fl=len(f);let tl=len(t)
    if tl>fl:
        var i=length
        while i>at+fl:i-=1;s[i+tl-fl-1]=s[i-1]
    elif tl<fl:
        for i in range(at+fl,length):s[i-(fl-tl)]=s[i]
    for i in range(tl):s[at+i]=t[i]
    length=length-fl+tl
fn ny_byte_replace(mut s:InlineArray[UInt8,64],at:Int,value:UInt8):
    s[at]=value
@export("nysiis_encoder")
fn nysiis_encoder(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65:return -1
    let length=a[0]
    if length<1 or length>64 or n!=c_size_t(length+1):return -1
    var s=InlineArray[UInt8,64]()
    for i in range(Int(length)):
        let x=a[i+1]
        if x<65 or (x>90 and x<97) or x>122:return -1
        s[i]=UInt8(x-32 if x>=97 else x)
    var pref_from=InlineArray[String,6]("");var pref_to=InlineArray[String,6]("")
    pref_from[0]="MAC";pref_from[1]="KN";pref_from[2]="K";pref_from[3]="PH";pref_from[4]="PF";pref_from[5]="SCH"
    pref_to[0]="MCC";pref_to[1]="NN";pref_to[2]="C";pref_to[3]="FF";pref_to[4]="FF";pref_to[5]="SSS"
    for i in range(6):
        if ny_match(s,Int(length),0,pref_from[i]):ny_replace(s,length,0,pref_from[i],pref_to[i]);break
    var suf_from=InlineArray[String,6]("");var suf_to=InlineArray[String,6]("")
    suf_from[0]="EE";suf_from[1]="IE";suf_from[2]="DT";suf_from[3]="RT";suf_from[4]="NT";suf_from[5]="ND"
    suf_to[0]="Y";suf_to[1]="Y";suf_to[2]="D";suf_to[3]="D";suf_to[4]="D";suf_to[5]="D"
    for i in range(6):
        let bytes=suf_from[i].as_bytes()
        if length>=len(bytes) and ny_match(s,Int(length),Int(length)-len(bytes),suf_from[i]):ny_replace(s,length,Int(length)-len(bytes),suf_from[i],suf_to[i]);break
    var rule_from=InlineArray[String,12]("");var rule_to=InlineArray[String,12]("")
    rule_from[0]="EV";rule_from[1]="E";rule_from[2]="I";rule_from[3]="O";rule_from[4]="U";rule_from[5]="Q";rule_from[6]="Z";rule_from[7]="M";rule_from[8]="KN";rule_from[9]="K";rule_from[10]="SCH";rule_from[11]="PH"
    rule_to[0]="AF";rule_to[1]="A";rule_to[2]="A";rule_to[3]="A";rule_to[4]="A";rule_to[5]="G";rule_to[6]="S";rule_to[7]="N";rule_to[8]="NN";rule_to[9]="C";rule_to[10]="SSS";rule_to[11]="FF"
    var i=1
    while i<Int(length):
        var changed=false
        for r in range(12):
            if ny_match(s,Int(length),i,rule_from[r]):ny_replace(s,length,i,rule_from[r],rule_to[r]);changed=true;break
        if not changed:
            let c=s[i];let prev=s[i-1]
            if c==72 and ((prev!=65 and prev!=69 and prev!=73 and prev!=79 and prev!=85) or (i+1<Int(length) and s[i+1]!=65 and s[i+1]!=69 and s[i+1]!=73 and s[i+1]!=79 and s[i+1]!=85)):
                ny_byte_replace(s,i,prev)
            elif c==87 and (prev==65 or prev==69 or prev==73 or prev==79 or prev==85):
                ny_byte_replace(s,i,prev)
        i+=1
    var write=1
    for j in range(1,Int(length)):
        if s[j]!=s[write-1]:s[write]=s[j];write+=1
    length=write
    if length>0 and s[Int(length)-1]==83:length-=1
    elif length>=2 and s[Int(length)-2]==65 and s[Int(length)-1]==89:length-=1
    elif length>0 and s[Int(length)-1]==65:length-=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(length):return -2
    for j in range(Int(length)):o[j]=s[j]
    return length
