from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn p59_allowed(value:Int)->Bool:
    return (value>=9 and value<=13) or (value>=32 and value<=126)
fn p59_lower(value:Int)->Int:
    return value+32 if value>=65 and value<=90 else value
fn p59_word_len(word:Int)->Int:
    if word==0 or word==4:return 3
    if word==6 or word==7:return 4
    return 2
fn p59_word_char(word:Int,pos:Int)->Int:
    if word==0:return 116 if pos==0 else (104 if pos==1 else 101)
    if word==1:return 98 if pos==0 else 101
    if word==2:return 116 if pos==0 else 111
    if word==3:return 111 if pos==0 else 102
    if word==4:return 97 if pos==0 else (110 if pos==1 else 100)
    if word==5:return 105 if pos==0 else 110
    if word==6:return 116 if pos==0 else (104 if pos==1 else (97 if pos==2 else 116))
    return 104 if pos==0 else (97 if pos==1 else (118 if pos==2 else 101))
fn p59_contains(input:UnsafePointer[Int64,ImmutAnyOrigin],length:Int,keys:InlineArray[UInt8,52728],index:Int,word:Int)->Bool:
    let width=p59_word_len(word)
    if length<width:return False
    for start in range(length-width+1):
        var matched=True
        for j in range(width):
            let pos=start+j;let value=Int(input[pos])^Int(keys[index*3+pos%3])
            if p59_lower(value)!=p59_word_char(word,j):matched=False;break
        if matched:return True
    return False
@export("problem59")
fn problem59(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>4096:return -1
    let n=Int(length)
    for i in range(n):if input[i]<0 or input[i]>255:return -1
    var keys=InlineArray[UInt8,52728](fill=0);var count=0
    for a in range(97,123):
        for b in range(97,123):
            for c in range(97,123):
                var valid=True
                for i in range(n):
                    let key=a if i%3==0 else (b if i%3==1 else c)
                    if !p59_allowed(Int(input[i])^key):valid=False;break
                if valid:keys[count*3]=UInt8(a);keys[count*3+1]=UInt8(b);keys[count*3+2]=UInt8(c);count+=1
    for word in range(8):
        var kept=0
        for i in range(count):
            if p59_contains(input,n,keys,i,word):
                if kept!=i:keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2]
                kept+=1
        count=kept
        if count==1:break
    if count==0:return -1
    var sum=Int64(0)
    for i in range(n):sum+=Int64(Int(input[i])^Int(keys[i%3]))
    return sum
