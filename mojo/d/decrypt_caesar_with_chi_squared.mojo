from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn caesar_frequency(i:Int)->Float64:
    if i==0:return 0.08497
    if i==1:return 0.01492
    if i==2:return 0.02202
    if i==3:return 0.04253
    if i==4:return 0.11162
    if i==5:return 0.02228
    if i==6:return 0.02015
    if i==7:return 0.06094
    if i==8:return 0.07546
    if i==9:return 0.00153
    if i==10:return 0.01292
    if i==11:return 0.04025
    if i==12:return 0.02406
    if i==13:return 0.06749
    if i==14:return 0.07507
    if i==15:return 0.01929
    if i==16:return 0.00095
    if i==17:return 0.07587
    if i==18:return 0.06327
    if i==19:return 0.09356
    if i==20:return 0.02758
    if i==21:return 0.00978
    if i==22:return 0.02560
    if i==23:return 0.00150
    if i==24:return 0.01994
    return 0.00077
fn caesar_store_f64(out:UnsafePointer[UInt8,MutAnyOrigin],value:Float64):
    let bits=bitcast[UInt64](value)
    for i in range(8):out[i]=UInt8((bits>>UInt(8*i))&255)
@export("decrypt_caesar_with_chi_squared")
fn decrypt_caesar_with_chi_squared(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>129:return -1
    let nn=input[0]
    if nn<0 or nn>128 or length!=c_size_t(nn+1):return -1
    let n=Int(nn)
    for i in range(n):
        if input[i+1]<0 or input[i+1]>127:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n+8):return -2
    var best_score:Float64=0.0;var best_shift=0;var best=List[Int](length=n,fill=0);var have=false
    for shift in range(26):
        var counts=List[Int](length=26,fill=0);var decoded=List[Int](capacity=128)
        for i in range(n):
            var value=Int(input[i+1])
            if value>=65 and value<=90:value+=32
            if value>=97 and value<=122:
                value=97+(value-97-shift+26)%26;counts[value-97]+=1
            decoded.append(value)
        var score:Float64=0.0
        for letter in range(26):
            let observed=counts[letter]
            if observed>0:
                let expected=caesar_frequency(letter)*Float64(observed)
                let difference=Float64(observed)-expected
                score+=(difference*difference)/expected
        var lex_less=false
        if have and score==best_score:
            for i in range(n):
                if decoded[i]!=best[i]:lex_less=decoded[i]<best[i];break
        if not have or score<best_score or (score==best_score and lex_less):
            have=true;best_score=score;best_shift=shift
            for i in range(n):best[i]=decoded[i]
    caesar_store_f64(out,best_score)
    for i in range(n):out[8+i]=UInt8(best[i])
    return Int64(best_shift)
