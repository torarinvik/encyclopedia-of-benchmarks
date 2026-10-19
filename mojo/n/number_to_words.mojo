from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn nw_small(x:Int)->String:
    if x==0:return "Zero"
    if x==1:return "One"
    if x==2:return "Two"
    if x==3:return "Three"
    if x==4:return "Four"
    if x==5:return "Five"
    if x==6:return "Six"
    if x==7:return "Seven"
    if x==8:return "Eight"
    if x==9:return "Nine"
    if x==10:return "Ten"
    if x==11:return "Eleven"
    if x==12:return "Twelve"
    if x==13:return "Thirteen"
    if x==14:return "Fourteen"
    if x==15:return "Fifteen"
    if x==16:return "Sixteen"
    if x==17:return "Seventeen"
    if x==18:return "Eighteen"
    return "Nineteen"
fn nw_add(mut out:InlineArray[UInt8,256],mut pos:Int,word:String):
    if pos>0:out[pos]=UInt8(32);pos+=1
    for b in word.as_bytes():out[pos]=b;pos+=1
fn nw_chunk(mut out:InlineArray[UInt8,256],mut pos:Int,value:Int):
    var x=value
    if x>=100:nw_add(out,pos,nw_small(x/100));nw_add(out,pos,"Hundred");x=x%100
    if x>=20:
        let tens=x/10
        if tens==2:nw_add(out,pos,"Twenty")
        elif tens==3:nw_add(out,pos,"Thirty")
        elif tens==4:nw_add(out,pos,"Forty")
        elif tens==5:nw_add(out,pos,"Fifty")
        elif tens==6:nw_add(out,pos,"Sixty")
        elif tens==7:nw_add(out,pos,"Seventy")
        elif tens==8:nw_add(out,pos,"Eighty")
        else:nw_add(out,pos,"Ninety")
        x=x%10
    if x>0:nw_add(out,pos,nw_small(x))
@export("number_to_words")
fn number_to_words(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>9:return -1
    let sign=a[0];let whole=a[1];let digits=a[2]
    if sign< -1 or sign>1 or whole<0 or whole>999999999999999 or digits<0 or digits>6 or n!=c_size_t(digits+3):return -1
    var nonzero=whole!=0
    for i in range(Int(digits)):
        if a[3+i]<0 or a[3+i]>9:return -1
        if a[3+i]!=0:nonzero=True
    if (nonzero and sign==0) or (not nonzero and sign!=0):return -1
    var staged=InlineArray[UInt8,256]();var pos=0
    if sign<0:nw_add(staged,pos,"Negative")
    var groups=InlineArray[Int64,5]();var rest=whole
    for i in range(5):groups[i]=rest%1000;rest=rest/1000
    var any=false
    for j in range(5):
        let i=4-j;let group=Int(groups[i])
        if group>0:
            nw_chunk(staged,pos,group)
            if i==4:nw_add(staged,pos,"Trillion")
            elif i==3:nw_add(staged,pos,"Billion")
            elif i==2:nw_add(staged,pos,"Million")
            elif i==1:nw_add(staged,pos,"Thousand")
            any=True
    if not any:nw_add(staged,pos,"Zero")
    var frac_nonzero=false
    for i in range(Int(digits)):if a[3+i]!=0:frac_nonzero=True
    if frac_nonzero:
        nw_add(staged,pos,"Point")
        for i in range(Int(digits)):nw_add(staged,pos,nw_small(Int(a[3+i])))
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):o[i]=staged[i]
    return Int64(pos)
