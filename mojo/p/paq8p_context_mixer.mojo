# PAQ8p bounded mixer profile. GPL-2.0-or-later; see package LICENSE.txt.
# Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak,
# Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson,
# Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, and KZ.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn paq_squash(d0: Int) -> Int:
    if d0>2047: return 4095
    if d0 < -2047: return 0
    let table=InlineArray[Int,33](1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094)
    let weight=d0 & 127
    let index=(d0 >> 7)+16
    return (table[index]*(128-weight)+table[index+1]*weight+64) >> 7

fn paq_dot(features: InlineArray[Int,8], weights: InlineArray[Int,32], offset: Int) -> Int:
    var sum=0
    for pair in range(4):
        let i=2*pair
        sum+=(features[i]*weights[offset+i]+features[i+1]*weights[offset+i+1]) >> 8
    return sum

fn paq_train(features: InlineArray[Int,8], mut weights: InlineArray[Int,32], offset: Int, error: Int):
    for i in range(8):
        let change=(((features[i]*error*2 >> 16)+1) >> 1)
        weights[offset+i]=max(-32768,min(32767,weights[offset+i]+change))

@export("paq8p_context_mixer")
fn paq8p_context_mixer(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<12 or length>177: return -1
    if input[0]<1 or input[0]>16: return -1
    let count=Int(input[0])
    if length!=c_size_t(1+11*count): return -1
    for step in range(count):
        let base=1+11*step
        for i in range(3):
            if input[base+i]<0 or input[base+i]>1: return -1
        for i in range(8):
            if input[base+3+i] < -2047 or input[base+3+i]>2047: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(2*count): return -2
    var stretch=InlineArray[Int,4096](fill=0)
    var previous=0
    for x in range(-2047,2048):
        let last=paq_squash(x)
        for p in range(previous,last+1): stretch[p]=x
        previous=last+1
    stretch[4095]=2047
    var outer=InlineArray[Int,32](fill=0)
    var inner=InlineArray[Int,32](fill=32767)
    var prior_input=InlineArray[Int,8](fill=0)
    var prior_prediction=2048; var prior_target=0
    for step in range(count):
        let base=1+11*step
        let c0=Int(input[base]); let c1=Int(input[base+1])+2; let target=Int(input[base+2])
        var features=InlineArray[Int,8](fill=0)
        for i in range(8): features[i]=Int(input[base+3+i])
        if step>0: paq_train(prior_input,inner,0,((prior_target << 12)-prior_prediction)*7)
        let p0=paq_squash(paq_dot(features,outer,8*c0) >> 5)
        let p1=paq_squash(paq_dot(features,outer,8*c1) >> 5)
        var inner_input=InlineArray[Int,8](fill=0)
        inner_input[0]=stretch[p0]; inner_input[1]=stretch[p1]
        let prediction=paq_squash(paq_dot(inner_input,inner,0) >> 8)
        output[2*step]=UInt8(prediction & 255)
        output[2*step+1]=UInt8((prediction >> 8) & 255)
        paq_train(features,outer,8*c0,((target << 12)-p0)*7)
        paq_train(features,outer,8*c1,((target << 12)-p1)*7)
        prior_input=inner_input^
        prior_prediction=prediction; prior_target=target
    return Int64(2*count)
