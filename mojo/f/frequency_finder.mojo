from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("frequency_finder")
fn frequency_finder(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() and length!=0:return -1
    if length>1024:return -1
    var counts=InlineArray[Int32,26](fill=0)
    for i in range(Int(length)):
        var b=input[i]
        if b<0 or b>127:return -1
        if b>=97 and b<=122:b-=32
        if b>=65 and b<=90:counts[Int(b-65)]+=1
    var order=InlineArray[Int32,26](fill=0)
    for i in range(26):order[i]=Int32(i)
    for i in range(1,26):
        let key=Int(order[i]);let keycount=counts[key]
        var rank=0
        for j in range(26):
            let eta=UInt8(69 if j==0 else 84 if j==1 else 65 if j==2 else 79 if j==3 else 73 if j==4 else 78 if j==5 else 83 if j==6 else 72 if j==7 else 82 if j==8 else 68 if j==9 else 76 if j==10 else 67 if j==11 else 85 if j==12 else 77 if j==13 else 87 if j==14 else 70 if j==15 else 71 if j==16 else 89 if j==17 else 80 if j==18 else 66 if j==19 else 86 if j==20 else 75 if j==21 else 74 if j==22 else 88 if j==23 else 81 if j==24 else 90)
            if Int(eta)==65+key:rank=j;break
        var j=i
        while j>0:
            let prev=Int(order[j-1]);var prank=0
            for t in range(26):
                let c=UInt8(69 if t==0 else 84 if t==1 else 65 if t==2 else 79 if t==3 else 73 if t==4 else 78 if t==5 else 83 if t==6 else 72 if t==7 else 82 if t==8 else 68 if t==9 else 76 if t==10 else 67 if t==11 else 85 if t==12 else 77 if t==13 else 87 if t==14 else 70 if t==15 else 71 if t==16 else 89 if t==17 else 80 if t==18 else 66 if t==19 else 86 if t==20 else 75 if t==21 else 74 if t==22 else 88 if t==23 else 81 if t==24 else 90)
                if Int(c)==65+prev:prank=t;break
            if counts[prev]>keycount or (counts[prev]==keycount and prank>rank):break
            order[j]=order[j-1];j-=1
        order[j]=Int32(key)
    var etaoin=InlineArray[UInt8,26](fill=0)
    for i in range(26):
        etaoin[i]=UInt8(69 if i==0 else 84 if i==1 else 65 if i==2 else 79 if i==3 else 73 if i==4 else 78 if i==5 else 83 if i==6 else 72 if i==7 else 82 if i==8 else 68 if i==9 else 76 if i==10 else 67 if i==11 else 85 if i==12 else 77 if i==13 else 87 if i==14 else 70 if i==15 else 71 if i==16 else 89 if i==17 else 80 if i==18 else 66 if i==19 else 86 if i==20 else 75 if i==21 else 74 if i==22 else 88 if i==23 else 81 if i==24 else 90)
    var score=0
    for i in range(6):
        for j in range(6):
            if 65+order[i]==Int32(etaoin[j]):score+=1;break
        for j in range(20,26):
            if 65+order[20+i]==Int32(etaoin[j]):score+=1;break
    return Int64(score)
