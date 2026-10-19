from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn halves_vowel(c:Int64)->Bool:
    return c==97 or c==101 or c==105 or c==111 or c==117 or c==65 or c==69 or c==73 or c==79 or c==85
@export("halves_are_alike")
fn halves_are_alike(letters:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>256 or length%2!=0 or (length>0 and letters==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let half=Int(length)//2;var first=0;var second=0
    for i in range(Int(length)):
        let c=letters[i]
        if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        if halves_vowel(c):
            if i<half:first+=1
            else:second+=1
    return 1 if first==second else 0
