# Clean-room bounded deterministic Sequitur grammar profile.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn sq_replace_pair(inout symbols: InlineArray[Int32, 16384],
        inout lengths: InlineArray[Int, 256], rule: Int, position: Int, token: Int32):
    for i in range(position+2, lengths[rule]):
        symbols[rule*64+i-1] = symbols[rule*64+i]
    lengths[rule] -= 1
    symbols[rule*64+position] = token

fn sq_find_duplicate(inout symbols: InlineArray[Int32, 16384],
        inout lengths: InlineArray[Int, 256], inout live: InlineArray[Bool, 256],
        next_rule: Int) -> InlineArray[Int, 7]:
    for r1 in range(next_rule):
        if not live[r1]: continue
        var p1 = 0
        while p1+1 < lengths[r1]:
            let left = symbols[r1*64+p1]
            let right = symbols[r1*64+p1+1]
            for r2 in range(r1, next_rule):
                if not live[r2]: continue
                var p2 = 0
                if r2 == r1: p2 = p1+2
                while p2+1 < lengths[r2]:
                    if symbols[r2*64+p2] == left and symbols[r2*64+p2+1] == right:
                        var found = InlineArray[Int, 7](fill=0)
                        found[0]=1;found[1]=r1;found[2]=p1;found[3]=r2;found[4]=p2
                        found[5]=Int(left);found[6]=Int(right)
                        return found
                    p2 += 1
            p1 += 1
    return InlineArray[Int, 7](fill=0)

fn sq_cleanup_one(inout symbols: InlineArray[Int32, 16384],
        inout lengths: InlineArray[Int, 256], inout live: InlineArray[Bool, 256],
        next_rule: Int) -> Bool:
    for target in range(1, next_rule):
        if not live[target]: continue
        var count=0;var parent=0;var position=0
        let token=Int32(256+target)
        for rule in range(next_rule):
            if live[rule]:
                for i in range(lengths[rule]):
                    if symbols[rule*64+i] == token:
                        count+=1;parent=rule;position=i
        if count==0:
            live[target]=False;lengths[target]=0;return True
        if count==1:
            var copy=InlineArray[Int32,64](fill=0)
            let replacement_length=lengths[target]
            for i in range(replacement_length): copy[i]=symbols[target*64+i]
            let delta=replacement_length-1
            let old_length=lengths[parent]
            var i=old_length
            while i>position+1:
                i-=1
                symbols[parent*64+i+delta]=symbols[parent*64+i]
            for i in range(replacement_length): symbols[parent*64+position+i]=copy[i]
            lengths[parent]+=delta;live[target]=False;lengths[target]=0
            return True
    return False

fn sq_normalize(inout symbols: InlineArray[Int32, 16384],
        inout lengths: InlineArray[Int, 256], inout live: InlineArray[Bool, 256],
        inout next_rule: Int):
    while True:
        while sq_cleanup_one(inout symbols, inout lengths, inout live, next_rule): pass
        let d=sq_find_duplicate(inout symbols, inout lengths, inout live, next_rule)
        if d[0] == 0: return
        var existing = -1
        for rule in range(1, next_rule):
            if live[rule] and lengths[rule]==2 and symbols[rule*64]==Int32(d[5]) and symbols[rule*64+1]==Int32(d[6]):
                existing=rule
                break
        if existing >= 0:
            var rule=d[1];var position=d[2]
            if rule==existing and position==0:rule=d[3];position=d[4]
            sq_replace_pair(inout symbols,inout lengths,rule,position,Int32(256+existing))
        else:
            let fresh=next_rule
            next_rule+=1
            live[fresh]=True;lengths[fresh]=2
            symbols[fresh*64]=Int32(d[5]);symbols[fresh*64+1]=Int32(d[6])
            let token=Int32(256+fresh)
            sq_replace_pair(inout symbols,inout lengths,d[3],d[4],token)
            sq_replace_pair(inout symbols,inout lengths,d[1],d[2],token)

@export("sequitur_grammar_induction")
fn sequitur_grammar_induction(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    if input[0] < 0 or input[0] > 64 or length != c_size_t(Int(input[0])+1): return -1
    let n=Int(input[0])
    for i in range(n):
        if input[i+1] < 0 or input[i+1] > 255: return -1
    var symbols=InlineArray[Int32,16384](fill=0)
    var lengths=InlineArray[Int,256](fill=0)
    var live=InlineArray[Bool,256](fill=False)
    live[0]=True
    var next_rule=1
    for i in range(n):
        symbols[lengths[0]]=Int32(input[i+1]);lengths[0]+=1
        sq_normalize(inout symbols,inout lengths,inout live,inout next_rule)
    var rules:Int64=0;var symbol_count:Int64=0
    for rule in range(next_rule):
        if live[rule]:
            if rule != 0: rules+=1
            symbol_count+=Int64(lengths[rule])
    return 1000*rules+symbol_count
