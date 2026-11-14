# Independent bounded Olden health simulation; see package README for source.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn health_push(v: Int, kind: Int, p: Int, mut heads: InlineArray[Int,340],
               mut tails: InlineArray[Int,340], mut next: InlineArray[Int,3400],
               mut previous: InlineArray[Int,3400]):
    let slot=4*v+kind; let tail=tails[slot]
    previous[p]=tail; next[p] = -1
    if tail>=0: next[tail]=p
    else: heads[slot]=p
    tails[slot]=p

fn health_remove(v: Int, kind: Int, p: Int, mut heads: InlineArray[Int,340],
                 mut tails: InlineArray[Int,340], mut next: InlineArray[Int,3400],
                 mut previous: InlineArray[Int,3400]):
    let slot=4*v+kind; let before=previous[p]; let after=next[p]
    if before>=0: next[before]=after
    else: heads[slot]=after
    if after>=0: previous[after]=before
    else: tails[slot]=before
    next[p] = -1; previous[p] = -1

fn health_random(v: Int, mut seed: InlineArray[Int64,85]) -> Float32:
    var state=seed[v] ^ 123459876
    let quotient=state//127773
    state=16807*(state-quotient*127773)-2836*quotient
    state=state ^ 123459876
    if state<0: state+=2147483647
    let value=Float32((1.0/2147483647.0)*Float64(state))
    seed[v]=Int64(value*Float32(2147483647))
    return value

fn health_admit(v: Int, p: Int, mut available: InlineArray[Int,85],
                mut heads: InlineArray[Int,340], mut tails: InlineArray[Int,340],
                mut next: InlineArray[Int,3400], mut previous: InlineArray[Int,3400],
                mut remaining: InlineArray[Int,3400], mut elapsed: InlineArray[Int,3400],
                mut visits: InlineArray[Int,3400]):
    visits[p]+=1
    if available[v]>0:
        available[v]-=1; remaining[p]=3; elapsed[p]+=3
        health_push(v,1,p,heads,tails,next,previous)
    else: health_push(v,0,p,heads,tails,next,previous)

@export("olden_health")
fn olden_health(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3: return -1
    if input[0]<1 or input[0]>4 or input[1]<0 or input[1]>40 or input[2]!=1: return -1
    let levels=Int(input[0]); let ticks=Int(input[1])
    var villages=0; var layer=1
    for _ in range(levels): villages+=layer; layer*=4
    var village_level=InlineArray[Int,85](fill=0)
    var available=InlineArray[Int,85](fill=0)
    var seed=InlineArray[Int64,85](fill=0)
    for v in range(villages):
        village_level[v]=levels if v==0 else village_level[(v-1)//4]-1
        available[v]=1 << (village_level[v]-1)
        seed[v]=Int64(v)*127774
    # Descending child order in recursive postorder.
    var order=InlineArray[Int,85](fill=0)
    var stack=InlineArray[Int,85](fill=0)
    var cursor=InlineArray[Int,85](fill=4)
    var sp=1; var order_count=0
    stack[0]=0
    while sp>0:
        let v=stack[sp-1]
        if cursor[v]>0:
            let child=4*v+cursor[v]; cursor[v]-=1
            if child<villages: stack[sp]=child; sp+=1
        else:
            order[order_count]=v; order_count+=1; sp-=1
    var heads=InlineArray[Int,340](fill=-1); var tails=InlineArray[Int,340](fill=-1)
    var next=InlineArray[Int,3400](fill=-1); var previous=InlineArray[Int,3400](fill=-1)
    var remaining=InlineArray[Int,3400](fill=0); var elapsed=InlineArray[Int,3400](fill=0)
    var visits=InlineArray[Int,3400](fill=0)
    var patient_count=0; var discharged=0
    for _ in range(ticks):
        for oi in range(order_count):
            let v=order[oi]
            for reverse in range(4):
                let child=4*v+4-reverse
                if child>=villages: continue
                var p=heads[4*child+3]
                while p>=0:
                    let after=next[p]
                    health_remove(child,3,p,heads,tails,next,previous)
                    health_admit(v,p,available,heads,tails,next,previous,remaining,elapsed,visits)
                    p=after
            var p=heads[4*v+2]
            while p>=0:
                let after=next[p]
                remaining[p]-=1
                if remaining[p]==0:
                    available[v]+=1
                    health_remove(v,2,p,heads,tails,next,previous)
                    discharged+=1
                p=after
            p=heads[4*v+1]
            while p>=0:
                let after=next[p]
                remaining[p]-=1
                if remaining[p]==0:
                    let random=health_random(v,seed)
                    health_remove(v,1,p,heads,tails,next,previous)
                    if Float64(random)>0.1 or v==0:
                        remaining[p]=10; elapsed[p]+=10
                        health_push(v,2,p,heads,tails,next,previous)
                    else:
                        available[v]+=1
                        health_push(v,3,p,heads,tails,next,previous)
                p=after
            p=heads[4*v]
            while p>=0:
                let after=next[p]
                if available[v]>0:
                    available[v]-=1; remaining[p]=3; elapsed[p]+=3
                    health_remove(v,0,p,heads,tails,next,previous)
                    health_push(v,1,p,heads,tails,next,previous)
                else: elapsed[p]+=1
                p=after
            if Float64(health_random(v,seed))>0.666:
                let fresh=patient_count; patient_count+=1
                health_admit(v,fresh,available,heads,tails,next,previous,remaining,elapsed,visits)
    return Int64(discharged)
