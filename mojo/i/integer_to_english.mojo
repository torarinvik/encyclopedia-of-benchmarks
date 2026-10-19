from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.collections import InlineArray

fn ite_small(n:Int)->String:
    if n==1:return "One"
    if n==2:return "Two"
    if n==3:return "Three"
    if n==4:return "Four"
    if n==5:return "Five"
    if n==6:return "Six"
    if n==7:return "Seven"
    if n==8:return "Eight"
    if n==9:return "Nine"
    if n==10:return "Ten"
    if n==11:return "Eleven"
    if n==12:return "Twelve"
    if n==13:return "Thirteen"
    if n==14:return "Fourteen"
    if n==15:return "Fifteen"
    if n==16:return "Sixteen"
    if n==17:return "Seventeen"
    if n==18:return "Eighteen"
    if n==19:return "Nineteen"
    return "Twenty"

fn ite_tens(n:Int)->String:
    if n==2:return "Twenty"
    if n==3:return "Thirty"
    if n==4:return "Forty"
    if n==5:return "Fifty"
    if n==6:return "Sixty"
    if n==7:return "Seventy"
    if n==8:return "Eighty"
    return "Ninety"

fn ite_word(mut out:List[UInt8],word:String):
    if len(out)>0:out.append(UInt8(32))
    for b in word.as_bytes():out.append(b)

fn ite_group(mut out:List[UInt8],value_arg:Int):
    var value=value_arg
    if value>=100:
        ite_word(mut out,ite_small(value//100));ite_word(mut out,"Hundred");value%=100
    if value==0:return
    if value<=20:ite_word(mut out,ite_small(value))
    elif value%10==0:ite_word(mut out,ite_tens(value//10))
    else:
        ite_word(mut out,ite_tens(value//10));ite_word(mut out,ite_small(value%10))

@export("integer_to_english")
fn integer_to_english(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                       output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]< -2147483648 or input[0]>2147483647:return -1
    let value=input[0]
    var stage=List[UInt8](capacity=128)
    if value==0:ite_word(mut stage,"Zero")
    elif value>0:
        var groups=InlineArray[Int32,4](fill=0);var count=0;var remaining=UInt32(value)
        while remaining!=0:groups[count]=Int32(remaining%1000);remaining/=1000;count+=1
        while count>0:
            count-=1
            if groups[count]!=0:
                ite_group(mut stage,Int(groups[count]))
                if count==1:ite_word(mut stage,"Thousand")
                elif count==2:ite_word(mut stage,"Million")
                elif count==3:ite_word(mut stage,"Billion")
    if c_size_t(len(stage))>capacity or (len(stage)>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(len(stage)):output[i]=stage[i]
    return Int64(len(stage))
