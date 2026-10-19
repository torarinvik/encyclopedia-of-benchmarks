from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime FM_MAX_TEXT=256
comptime FM_MAX_KEY=64
comptime FM_MAX_MORSE=1300
comptime FM_MAX_RESULT=800

fn fm_code(i:Int)->UInt8:
    if i==0:return 1
    if i==1:return 8
    if i==2:return 10
    if i==3:return 4
    if i==4:return 0
    if i==5:return 2
    if i==6:return 6
    if i==7:return 0
    if i==8:return 0
    if i==9:return 7
    if i==10:return 5
    if i==11:return 4
    if i==12:return 3
    if i==13:return 2
    if i==14:return 7
    if i==15:return 6
    if i==16:return 13
    if i==17:return 2
    if i==18:return 0
    if i==19:return 1
    if i==20:return 1
    if i==21:return 1
    if i==22:return 3
    if i==23:return 9
    if i==24:return 11
    return 12

fn fm_len(i:Int)->UInt8:
    if i==0:return 2
    if i==1:return 4
    if i==2:return 4
    if i==3:return 3
    if i==4:return 1
    if i==5:return 4
    if i==6:return 3
    if i==7:return 4
    if i==8:return 2
    if i==9:return 4
    if i==10:return 3
    if i==11:return 4
    if i==12:return 2
    if i==13:return 2
    if i==14:return 3
    if i==15:return 4
    if i==16:return 4
    if i==17:return 3
    if i==18:return 3
    if i==19:return 1
    if i==20:return 3
    if i==21:return 4
    if i==22:return 3
    return 4

fn fm_morse_letter(symbols:InlineArray[UInt8,FM_MAX_MORSE],start:Int,n:Int)->Int:
    var code:UInt8=0
    for i in range(n):code=code*2+UInt8(1 if symbols[start+i]==45 else 0)
    for i in range(26):
        if Int(fm_len(i))==n and fm_code(i)==code:return i
    return -1

@export("fractionated_morse_cipher")
fn fractionated_morse_cipher(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                             output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>323:return -1
    let mode=input[0];let textn=input[1];let keyn=input[2]
    if (mode!=0 and mode!=1) or textn<0 or textn>FM_MAX_TEXT or keyn<0 or keyn>FM_MAX_KEY or Int(length)!=3+Int(textn)+Int(keyn):return -1
    let text=Int(textn);let key_start=3+text
    for i in range(Int(keyn)):
        let v=input[key_start+i]
        if not ((v>=65 and v<=90) or (v>=97 and v<=122)):return -1
    for i in range(text):
        let v=input[3+i]
        if mode==0:
            if v!=32 and not ((v>=65 and v<=90) or (v>=97 and v<=122)):return -1
        elif v<65 or v>90:return -1
    var keyed=InlineArray[UInt8,26](fill=0)
    var used=InlineArray[Bool,26](fill=False);var kc=0
    for i in range(Int(keyn)):
        var v=input[key_start+i]
        if v>=97:v-=32
        let idx=Int(v-65)
        if not used[idx]:used[idx]=True;keyed[kc]=UInt8(v);kc+=1
    for i in range(26):
        if not used[i]:keyed[kc]=UInt8(65+i);kc+=1
    var morse=InlineArray[UInt8,FM_MAX_MORSE](fill=0);var mn=0
    var result=InlineArray[UInt8,FM_MAX_RESULT](fill=0);var rn=0
    if mode==0:
        for i in range(text):
            if i!=0:morse[mn]=120;mn+=1
            var v=input[3+i]
            if v==32:continue
            if v>=97:v-=32
            let li=Int(v-65)
            for bit in range(Int(fm_len(li))):
                let mask=UInt8(1) << UInt8(Int(fm_len(li))-bit-1)
                morse[mn]=UInt8(45 if (fm_code(li)&mask)!=0 else 46);mn+=1
        let pad=3-mn%3
        for _ in range(pad):morse[mn]=120;mn+=1
        var i=0
        while i<mn:
            var tri=0
            for j in range(3):
                let symbol=morse[i+j]
                tri=tri*3+(0 if symbol==46 else 1 if symbol==45 else 2)
            if tri<26:result[rn]=keyed[tri];rn+=1
            i+=3
    else:
        for i in range(text):
            var tri=0
            while tri<26 and keyed[tri]!=UInt8(input[3+i]):tri+=1
            if tri==26:return -1
            var symbols=InlineArray[UInt8,3](fill=0)
            symbols[0]=UInt8(46 if tri//9==0 else 45 if tri//9==1 else 120)
            symbols[1]=UInt8(46 if (tri//3)%3==0 else 45 if (tri//3)%3==1 else 120)
            symbols[2]=UInt8(46 if tri%3==0 else 45 if tri%3==1 else 120)
            for j in range(3):morse[mn]=symbols[j];mn+=1
        var seg=0
        for i in range(mn+1):
            if i<mn and morse[i]!=120:continue
            let seglen=i-seg
            if seglen==0:result[rn]=32;rn+=1
            else:
                let letter=fm_morse_letter(morse,seg,seglen)
                if letter<0:return -1
                result[rn]=UInt8(65+letter);rn+=1
            seg=i+1
        var first=0
        while first<rn and result[first]==32:first+=1
        while rn>first and result[rn-1]==32:rn-=1
        if first>0:
            for i in range(rn-first):result[i]=result[first+i]
            rn-=first
    if capacity<c_size_t(rn) or (rn!=0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(rn):output[i]=result[i]
    return Int64(rn)
