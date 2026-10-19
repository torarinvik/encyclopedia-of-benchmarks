from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wtn_word(a:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,length:Int)->Int:
    var code:Int64=0
    for i in range(length):
        var c=a[start+i]
        if c>=65 and c<=90:c+=32
        if c<97 or c>122:return 0
        code=code*27+c-96
    if length==4 and code==515904:return 1
    if length==3 and code==11318:return 2
    if length==3 and code==15216:return 3
    if length==5 and code==10799546:return 4
    if length==4 and code==129618:return 5
    if length==4 and code==125258:return 6
    if length==3 and code==14118:return 7
    if length==5 and code==10211981:return 8
    if length==5 and code==2839691:return 9
    if length==4 and code==282506:return 10
    if length==3 and code==14729:return 11
    if length==6 and code==78236429:return 12
    if length==6 and code==299309045:return 13
    if length==8 and code==212445531527:return 14
    if length==8 and code==68884716992:return 15
    if length==7 and code==2457249197:return 16
    if length==7 and code==7503281492:return 17
    if length==9 and code==5427065792075:return 18
    if length==8 and code==55893641747:return 19
    if length==8 and code==150135668600:return 20
    if length==6 and code==299310469:return 21
    if length==6 and code==291420502:return 22
    if length==5 and code==3497578:return 23
    if length==5 and code==3370732:return 24
    if length==5 and code==10292587:return 25
    if length==7 and code==7444534714:return 26
    if length==6 and code==76671682:return 27
    if length==6 and code==205947439:return 28
    if length==7 and code==3408223126:return 29
    if length==8 and code==212533196926:return 30
    if length==7 and code==5172226988:return 31
    if length==7 and code==910601609:return 32
    if length==8 and code==216316393493:return 33
    if length==3 and code==1111:return 34
    if length==5 and code==8805260:return 35
    if length==8 and code==148483421897:return 36
    return 0
fn wtn_val(id:Int)->Int64:
    if id>=1 and id<=20:return Int64(id-1)
    if id>=21 and id<=28:return Int64((id-19)*10)
    return -1
fn wtn_digits(v:Int64)->Int:
    var x=v;var d=1
    while x>=10:x/=10;d+=1
    return d
fn wtn_uint(v:Int64,inout out:InlineArray[UInt8,64],inout p:Int):
    var x=v;var d=InlineArray[UInt8,24]();var n=0
    if x==0:d[0]=48;n=1
    while x>0:d[n]=UInt8(48+x%10);n+=1;x/=10
    while n>0:n-=1;out[p]=d[n];p+=1
@export("words_to_number")
fn words_to_number(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let bl=a[0]
    if bl<0 or bl>128 or n!=c_size_t(bl+1):return -1
    var ids=InlineArray[Int32,128]();var count=0;var start= -1
    for i in range(Int(bl)):
        let c=a[i+1]
        if c<32 or c>126:return -1
        if c==32 or c==44 or c==45:
            if start>=0:ids[count]=Int32(wtn_word(a,start+1,i-start));count+=1;start= -1
        elif start<0:start=i
    if start>=0:ids[count]=Int32(wtn_word(a,start+1,Int(bl)-start));count+=1
    if count==0:return -3
    let negative=ids[0]==36;let begin=1 if negative else 0
    var chunks=InlineArray[Int64,128]();var chunkn=0;var current:Int64=0;var prevhund=false;var prevscale=false;var fraction=InlineArray[UInt8,64]();var fn=0;var fnwords=0;var point=false;var err:Int64=0
    var i=begin
    while i<count:
        let id=Int(ids[i])
        if id==34:
            if i+1>=count:err= -10;break
            let nv=wtn_val(Int(ids[i+1]));let after=if i+2<count then Int(ids[i+2]) else -1
            if (not prevhund and not prevscale) or nv<0 or not (nv>=10 or after== -1 or after==35):err= -10;break
            i+=1;continue
        if id==29:
            if current>=10 or prevscale:err= -5;break
            if current==0:current=1
            current*=100;prevhund=True;i+=1;continue
        prevhund=False
        if id>=30 and id<=33:
            if current==0 or prevscale:err= -5;break
            var scale:Int64=1000
            if id==31:scale=1000000
            elif id==32:scale=1000000000
            elif id==33:scale=1000000000000
            let value=current*scale
            if chunkn>0 and wtn_digits(chunks[chunkn-1])<=wtn_digits(value):err= -5;break
            chunks[chunkn]=value;chunkn+=1;current=0;prevscale=True;i+=1;continue
        prevscale=False;let value=wtn_val(id)
        if value>=0:
            if value==0 and not (current==0 and chunkn==0):err= -5;break
            if current!=0 and wtn_digits(current)<=wtn_digits(value):err= -5;break
            current+=value;i+=1;continue
        if id==35:
            if current!=0:chunks[chunkn]=current;chunkn+=1
            current=0;point=True
            for j in range(i+1,count):
                let digit=wtn_val(Int(ids[j]))
                if digit<0:err= -6;break
                fnwords+=1
                if fnwords>3:err= -1;break
                wtn_uint(digit,fraction,fn)
            if err!=0:break
            if fn==0:err= -7
            break
        if id==36:err= -9 if not negative else -8;break
        err= -4;break
    if err!=0:return err
    if current!=0:chunks[chunkn]=current;chunkn+=1
    var total:Int64=0
    for j in range(chunkn):total+=chunks[j]
    var fraction_nonzero=false
    for j in range(fn):if fraction[j]!=48:fraction_nonzero=true
    var staged=InlineArray[UInt8,64]();var p=0
    if negative and (total!=0 or fraction_nonzero):staged[p]=45;p+=1
    wtn_uint(total,staged,p)
    if point:staged[p]=46;p+=1;for j in range(fn):staged[p]=fraction[j];p+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(p):return -2
    for j in range(p):o[j]=staged[j]
    return Int64(p)
