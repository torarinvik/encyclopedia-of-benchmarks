from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime ENIGMA_R1:InlineArray[Int64,26]=[4,6,25,22,21,14,13,0,7,3,2,11,5,16,12,18,8,15,9,1,24,20,10,23,19,17]
comptime ENIGMA_R2:InlineArray[Int64,26]=[5,14,1,7,12,3,10,4,23,16,13,17,0,20,11,15,6,18,9,21,19,24,8,2,25,22]
comptime ENIGMA_R3:InlineArray[Int64,26]=[25,9,23,4,18,8,20,16,11,7,0,21,17,12,3,14,24,6,19,13,5,22,15,1,10,2]
fn enigma_mod(value:Int)->Int:
    let result=value%26
    return result+26 if result<0 else result
fn enigma_wire(rotor:Int,index:Int)->Int:
    if rotor==0:return Int(ENIGMA_R1[index])
    if rotor==1:return Int(ENIGMA_R2[index])
    return Int(ENIGMA_R3[index])
@export("enigma_machine2")
fn enigma_machine2(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>16:return -1
    let n=input[0]
    if n<0 or n>12 or length!=c_size_t(4+n):return -1
    var pos=InlineArray[Int,3](fill=0)
    for r in range(3):
        if input[1+r]<1 or input[1+r]>26:return -1
        pos[r]=Int(input[1+r])-1
    for i in range(Int(n)):
        if input[4+i]<0 or input[4+i]>25:return -1
    var result:Int64=0
    for i in range(Int(n)):
        var x=Int(input[4+i])
        for r in range(3):x=enigma_wire(r,enigma_mod(x+pos[r]))
        x=enigma_mod(x+13)
        for rr in range(3):
            let r=2-rr;var z=0
            while z<26 and enigma_wire(r,z)!=x:z+=1
            x=enigma_mod(z-pos[r])
        result=result*26+Int64(x)
        pos[0]+=1
        if pos[0]==26:
            pos[0]=0;pos[1]+=1
            if pos[1]==26:pos[1]=0;pos[2]=(pos[2]+1)%26
    return result
