# Raymond Chen, Copyright 1991; freely distributable when alterations are
# clearly indicated. This independent bounded port replaces file and console
# I/O with a packed integer-array interface and returns the solution count.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn anagram_letter(value: Int64) -> Int:
    if value>=97 and value<=122: return Int(value-97)
    if value>=65 and value<=90: return Int(value-65)
    return -1

fn anagram_search(mut words: InlineArray[UInt64,12], mut sizes: InlineArray[Int,12],
                  count: Int, order: InlineArray[Int,26], fields: InlineArray[UInt64,26],
                  remaining: UInt64, remaining_length: Int, start: Int, pivot_start: Int) -> Int64:
    if remaining_length==0: return 1
    var position=pivot_start
    while position<26 and (remaining & fields[order[position]])==0: position+=1
    if position==26: return 0
    let pivot=order[position]
    var end=count; var index=start; var solutions=Int64(0)
    while index<end:
        let word=words[index]; let size=sizes[index]
        # Test each packed field before subtraction, preventing cross-field
        # borrows while retaining the packed-count representation.
        var fits=True
        for letter in range(26):
            if (word & fields[letter])>(remaining & fields[letter]): fits=False; break
        if not fits:
            index+=1
            continue
        if (word & fields[pivot])==0:
            words[index]=words[end-1]; words[end-1]=word
            sizes[index]=sizes[end-1]; sizes[end-1]=size
            end-=1
            continue
        let next_length=remaining_length-size
        if next_length==0: solutions+=1
        else: solutions+=anagram_search(words,sizes,count,order,fields,remaining-word,next_length,index,position)
        index+=1
    return solutions

@export("ptrdist_anagram")
fn ptrdist_anagram(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>222: return -1
    if input[0]<1 or input[0]>16: return -1
    let phrase_length=Int(input[0]); let count_at=phrase_length+1
    if count_at>=Int(length) or input[count_at]<0 or input[count_at]>12: return -1
    var phrase=InlineArray[Int,26](fill=0)
    for i in range(phrase_length):
        let letter=anagram_letter(input[1+i])
        if letter<0: return -1
        phrase[letter]+=1
    var fields=InlineArray[UInt64,26](fill=0)
    var shifts=InlineArray[Int,26](fill=0)
    var phrase_mask=UInt64(0); var shift=0
    for letter in range(26):
        let frequency=phrase[letter]
        if frequency==0: continue
        var bits=1
        while (1 << bits)<=frequency: bits+=1
        if shift+bits+1>64: return -1
        fields[letter]=(UInt64(1 << bits)-1) << UInt(shift)
        shifts[letter]=shift
        phrase_mask |= UInt64(frequency) << UInt(shift)
        shift+=bits+1
    var words=InlineArray[UInt64,12](fill=0); var sizes=InlineArray[Int,12](fill=0)
    var frequencies=InlineArray[Int,26](fill=0)
    var candidates=0; var offset=count_at+1
    for _ in range(Int(input[count_at])):
        if offset>=Int(length) or input[offset]<1 or input[offset]>16: return -1
        let size=Int(input[offset]); offset+=1
        if offset+size>Int(length): return -1
        var counts=InlineArray[Int,26](fill=0)
        for i in range(size):
            let letter=anagram_letter(input[offset+i])
            if letter<0: return -1
            counts[letter]+=1
        var fits=True
        for letter in range(26):
            if counts[letter]>phrase[letter]: fits=False
        if fits and ((size>=2 and size+2<=phrase_length) or size==phrase_length):
            var word=UInt64(0)
            for letter in range(26):
                word |= UInt64(counts[letter]) << UInt(shifts[letter])
                frequencies[letter]+=counts[letter]
            words[candidates]=word; sizes[candidates]=size; candidates+=1
        offset+=size
    if offset!=Int(length): return -1
    var order=InlineArray[Int,26](fill=0)
    for i in range(26): order[i]=i
    for i in range(1,26):
        let key=order[i]
        let key_frequency=frequencies[key] if frequencies[key]!=0 else 2147483647
        var j=i
        while j>0:
            let prev=order[j-1]
            let prev_frequency=frequencies[prev] if frequencies[prev]!=0 else 2147483647
            if prev_frequency<key_frequency or (prev_frequency==key_frequency and prev<key): break
            order[j]=prev; j-=1
        order[j]=key
    return anagram_search(words,sizes,candidates,order,fields,phrase_mask,phrase_length,0,0)
