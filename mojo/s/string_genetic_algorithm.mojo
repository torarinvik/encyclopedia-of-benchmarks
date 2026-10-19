from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime POP=200
fn ga_rand(state:UnsafePointer[UInt32,MutAnyOrigin])->UInt32:
    state[0]=UInt32((UInt64(state[0])*48271)%2147483647);return state[0]
@export("string_genetic_algorithm")
fn string_genetic_algorithm(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>44:return -2
    let tl=v[0];let gc=v[1];let seed=v[2];let mg=v[3]
    if tl<1 or tl>8 or gc<1 or gc>32 or seed<1 or seed>=2147483647 or mg<1 or mg>1000 or n!=c_size_t(4+tl+gc):return -2
    let tlen=Int(tl);let genesn=Int(gc)
    var target=InlineArray[UInt8,8](fill=0);var genes=InlineArray[UInt8,32](fill=0)
    for i in range(tlen):if v[4+i]<32 or v[4+i]>126:return -2;target[i]=UInt8(v[4+i])
    for i in range(genesn):if v[4+tlen+i]<32 or v[4+tlen+i]>126:return -2;genes[i]=UInt8(v[4+tlen+i])
    for i in range(tlen):
        var found=False
        for j in range(genesn):if target[i]==genes[j]:found=True
        if not found:return -2
    if o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var state=InlineArray[UInt32,1](UInt32(seed));var pop=InlineArray[UInt64,200](fill=0);var nextpop=InlineArray[UInt64,200](fill=0);var scores=InlineArray[UInt8,200](fill=0);var order=InlineArray[Int,200](fill=0)
    for ind in range(POP):
        var word:UInt64=0
        for p in range(tlen):let gene=genes[Int(ga_rand(state.unsafe_ptr())%UInt32(genesn))];word=word|(UInt64(gene)<<UInt(8*p))
        pop[ind]=word
    var total:Int64=0
    for gen in range(1,Int(mg)+1):
        total+=200
        for ind in range(POP):
            var score=0
            for p in range(tlen):if UInt8((pop[ind]>>UInt(8*p))&255)==target[p]:score+=1
            scores[ind]=UInt8(score);order[ind]=ind
            if score==tlen:
                if cap<16:return -2
                for w in range(2):let x=if w==0 then Int64(gen) else total;let bits=bitcast[UInt64](x);for b in range(8):o[w*8+b]=UInt8((bits>>UInt(8*b))&255)
                return 16
        for i in range(1,POP):
            let selected=order[i];var j=i
            while j>0 and scores[order[j-1]]<scores[selected]:order[j]=order[j-1];j-=1
            order[j]=selected
        var nc=0
        while nc<66:nextpop[nc]=pop[order[nc]];nc+=1
        for rank in range(50):
            if nc>=POP:break
            let first=pop[order[rank]];let childcount=Int(scores[order[rank]])*100/tlen+1
            for _ in range(if childcount<10 then childcount else 10):
                if nc>=POP:break
                let second=pop[order[Int(ga_rand(state.unsafe_ptr())%51)]];let cut=Int(ga_rand(state.unsafe_ptr())%UInt32(tlen));var children=InlineArray[UInt64,2](fill=0)
                for p in range(tlen):
                    let shift=UInt(8*p);let a=(first>>shift)&255;let b=(second>>shift)&255
                    children[0]=children[0]|((if p<cut then a else b)<<shift);children[1]=children[1]|((if p<cut then b else a)<<shift)
                for ci in range(2):
                    if ga_rand(state.unsafe_ptr())%5<2:
                        let p=Int(ga_rand(state.unsafe_ptr())%UInt32(tlen));let sh=UInt(8*p);let replacement=UInt64(genes[Int(ga_rand(state.unsafe_ptr())%UInt32(genesn))]);children[ci]=(children[ci]&~(UInt64(255)<<sh))|(replacement<<sh)
                    if nc<POP:nextpop[nc]=children[ci];nc+=1
                if nc==POP:break
            if nc==POP:break
        pop=nextpop
    return -1
