from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import log2, floor

fn entropy_round_even(value:Float64)->Int:
    let low=floor(value);let frac=value-low;var whole=Int(low)
    if frac>0.5 or (frac==0.5 and whole%2!=0):whole+=1
    return whole
fn entropy_symbol(c:Int)->Bool:
    return c==32 or (c>=97 and c<=122)
fn entropy_append_line(output:List[UInt8],value:Int):
    var mag=value
    if mag<0:output.append(UInt8(45));mag= -mag
    if mag>=10:output.append(UInt8(48+mag//10))
    output.append(UInt8(48+mag%10));output.append(UInt8(46));output.append(UInt8(48));output.append(UInt8(10))
@export("entropy")
fn entropy(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>513:return -1
    let n=input[0]
    if n<1 or n>512 or length!=c_size_t(n+1):return -1
    var singles=InlineArray[Int64,128](fill=0);var pairs=InlineArray[Int64,16384](fill=0)
    for i in range(Int(n)):
        let c=input[i+1]
        if c<0 or c>=128:return -1
        singles[Int(c)]+=1
    pairs[32*128+Int(input[1])]+=1
    for i in range(Int(n)-1):pairs[Int(input[i+1])*128+Int(input[i+2])]+=1
    var single_entropy:Float64=0.0;var bigram_entropy:Float64=0.0
    for c in range(128):
        if entropy_symbol(c) and singles[c]>0:
            let p=Float64(singles[c])/Float64(n);single_entropy-=p*log2(p)
    for a in range(128):
        if not entropy_symbol(a):continue
        for b in range(128):
            if not entropy_symbol(b):continue
            let count=pairs[a*128+b]
            if count>0:
                let p=Float64(count)/Float64(n);bigram_entropy-=p*log2(p)
    let s1=entropy_round_even(single_entropy);let s2=entropy_round_even(bigram_entropy);let diff=entropy_round_even(bigram_entropy-single_entropy)
    var staged=List[UInt8](capacity=13)
    entropy_append_line(staged,s1);entropy_append_line(staged,s2);entropy_append_line(staged,diff)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(staged)):return -2
    for i in range(len(staged)):output[i]=staged[i]
    return Int64(len(staged))
