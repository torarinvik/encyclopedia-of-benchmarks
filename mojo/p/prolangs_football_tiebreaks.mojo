# Independent bounded Prolangs-C football tie-break profile.
# William Landi (1991); permission to use is granted if the copyright notice
# remains in place. See the package README for the pinned source and rights.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn football_score(v: UnsafePointer[Int64,ImmutAnyOrigin], n: Int, ids: InlineArray[Int,8],
                  start: Int, count: Int, team: Int, stage: Int, same: Bool) -> (Int64,Int64):
    if stage==0:
        let wins=1+12*n; let ties=wins+n*n
        var won=Int64(0); var lost=Int64(0); var tied=Int64(0)
        for i in range(start,start+count):
            let other=ids[i]
            if other!=team:
                won+=v[wins+team*n+other]; lost+=v[wins+other*n+team]; tied+=v[ties+team*n+other]
        let games=won+lost+tied
        return (2*won+tied,1 if games==0 else 2*games)
    let base=1+12*team
    if stage<=3:
        let field=2*stage+1
        return (v[base+field],1 if v[base+field+1]==0 else 2*v[base+field+1])
    if stage==4: return (v[base+(9 if same else 10)],1)
    return (v[base+11],1)

fn football_same(v: UnsafePointer[Int64,ImmutAnyOrigin], ids: InlineArray[Int,8], start: Int, count: Int) -> Bool:
    let base=1+12*ids[start]
    for i in range(start+1,start+count):
        let other=1+12*ids[i]
        if v[base+1]!=v[other+1] or v[base+2]!=v[other+2]: return False
    return True

fn football_resolve(v: UnsafePointer[Int64,ImmutAnyOrigin], n: Int, mut ids: InlineArray[Int,8],
                    start: Int, count: Int, stage: Int):
    if count<=1 or stage>=6: return
    let same=football_same(v,ids,start,count)
    if stage==0 and not same and count>2:
        let wins=1+12*n; let ties=wins+n*n
        for i in range(start,start+count):
            let team=ids[i]
            var all_win=True; var all_lose=True
            for j in range(start,start+count):
                let other=ids[j]
                if other==team: continue
                let won=v[wins+team*n+other]; let lost=v[wins+other*n+team]; let tied=v[ties+team*n+other]
                if won+lost+tied==0 or tied!=0: all_win=False; all_lose=False
                if lost!=0: all_win=False
                if won!=0: all_lose=False
            if all_win:
                let old=ids[start]; ids[start]=team; ids[i]=old
                football_resolve(v,n,ids,start+1,count-1,0)
                return
            if all_lose:
                let last=start+count-1; let old=ids[last]; ids[last]=team; ids[i]=old
                football_resolve(v,n,ids,start,count-1,0)
                return
        football_resolve(v,n,ids,start,count,1)
        return
    if stage==1 and not same:
        football_resolve(v,n,ids,start,count,2)
        return
    if stage==3:
        for i in range(start,start+count):
            if v[1+12*ids[i]+8]<4:
                football_resolve(v,n,ids,start,count,4)
                return
    # Keep the complete original group available while sorting score keys.
    var original=InlineArray[Int,8](fill=0)
    for i in range(start,start+count): original[i]=ids[i]
    for i in range(start+1,start+count):
        let item=ids[i]; let score=football_score(v,n,original,start,count,item,stage,same)
        var j=i
        while j>start:
            let prior=football_score(v,n,original,start,count,ids[j-1],stage,same)
            if score[0]*prior[1]<=prior[0]*score[1]: break
            ids[j]=ids[j-1]; j-=1
        ids[j]=item
    let best=football_score(v,n,original,start,count,ids[start],stage,same)
    var split=False
    for i in range(start+1,start+count):
        let score=football_score(v,n,original,start,count,ids[i],stage,same)
        if best[0]*score[1]!=score[0]*best[1]: split=True
    if not split:
        football_resolve(v,n,ids,start,count,stage+1)
        return
    var group=start
    while group<start+count:
        var end=group+1
        let score=football_score(v,n,original,start,count,ids[group],stage,same)
        while end<start+count:
            let next=football_score(v,n,original,start,count,ids[end],stage,same)
            if score[0]*next[1]!=next[0]*score[1]: break
            end+=1
        football_resolve(v,n,ids,group,end-group,0)
        group=end

@export("prolangs_football_tiebreaks")
fn prolangs_football_tiebreaks(values: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or values[0]<2 or values[0]>8: return -2
    let n=Int(values[0]); let cells=n*n
    if length!=c_size_t(1+12*n+2*cells): return -2
    var ids=InlineArray[Int,8](fill=0)
    for i in range(n):
        let base=1+12*i; let id=values[base]
        if id<0 or id>31 or values[base+1]<0 or values[base+1]>1 or values[base+2]<0 or values[base+2]>2: return -2
        ids[i]=i
        for field in range(3,9,2):
            let points=values[base+field]; let games=values[base+field+1]
            if games<0 or games>64 or points<0 or points>2*games: return -2
        for field in range(9,12):
            if values[base+field] < -4096 or values[base+field]>4096: return -2
        for j in range(i):
            if values[1+12*j]==id: return -2
    let wins=1+12*n; let ties=wins+cells
    for i in range(n):
        for j in range(n):
            let w=values[wins+i*n+j]; let t=values[ties+i*n+j]
            if w<0 or w>64 or t<0 or t>64: return -2
            if (i==j and (w!=0 or t!=0)) or t!=values[ties+j*n+i]: return -2
    for i in range(1,n):
        let item=ids[i]; let base=1+12*item; var j=i
        while j>0:
            let previous=1+12*ids[j-1]
            if values[previous+1]<values[base+1] or (values[previous+1]==values[base+1] and values[previous]<=values[base]): break
            ids[j]=ids[j-1]; j-=1
        ids[j]=item
    football_resolve(values,n,ids,0,n,0)
    var result=Int64(0)
    for i in range(n): result=result*32+values[1+12*ids[i]]
    return result
