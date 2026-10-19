from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite
@extern("C") fn rand() -> Int32
fn tgen_rand()->Int:
    return Int(rand())
fn tgen_unit()->Float64:
    return Float64(tgen_rand())/2147483647.0
fn tgen_index(max_inclusive:Int)->Int:
    return tgen_rand()%(max_inclusive+1)
fn tgen_distance(x0:Int64,y0:Int64,x1:Int64,y1:Int64)->Float64:
    let dx=Float64(x0-x1);let dy=Float64(y0-y1)
    return sqrt(dx*dx+dy*dy)
fn tgen_fitness(pop:InlineArray[InlineArray[Int32,3],8],size:Int,x0:Int64,y0:Int64,x1:Int64,y1:Int64,inout fitness:InlineArray[Float64,8],inout best:InlineArray[Int32,3],inout best_distance:Float64):
    for person in range(size):
        var total:Float64=0.0
        for i in range(2):
            let left=Int(pop[person][i]);let right=Int(pop[person][i+1])
            total+=tgen_distance(x0 if left==0 else x1,y0 if left==0 else y1,x0 if right==0 else x1,y0 if right==0 else y1)
        fitness[person]=1.0/total
        if total<best_distance:best=pop[person];best_distance=total
fn tgen_repair(inout chrom:InlineArray[Int32,3],start:Int,end:Int):
    var dup=false
    for i in range(3):for j in range(i):if chrom[i]==chrom[j]:dup=true
    if not dup:return
    for segment in range(end-start+1):
        let current=start+segment;var target=0
        for ci in range(1,2):
            if ci!=current and chrom[ci]==chrom[current]:target=ci;break
        if target!=0:
            var available=1
            for i in range(3):if chrom[i]==1:available=0
            if available>0:chrom[target]=1
@export("travelling_salesman_python_genetic")
fn travelling_salesman_python_genetic(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=8:return -1
    for i in range(8):
        if not isfinite(a[i]):return -1
    if a[0]<2.0 or a[0]>8.0 or Float64(Int64(a[0]))!=a[0] or Int64(a[0])%2!=0 or a[1]<0.0 or a[1]>12.0 or Float64(Int64(a[1]))!=a[1] or a[2]<0.0 or a[2]>1.0 or a[3]<0.0 or a[3]>1.0:return -1
    for i in range(4,8):if a[i]< -16.0 or a[i]>16.0 or Float64(Int64(a[i]))!=a[i]:return -1
    if a[4]==a[6] and a[5]==a[7]:return -1
    let x0=Int64(a[4]);let y0=Int64(a[5]);let x1=Int64(a[6]);let y1=Int64(a[7])
    let size=Int(a[0]);let iterations=Int(a[1]);let crossover=a[2];let mutation=a[3]
    var pop=InlineArray[InlineArray[Int32,3],8]()
    for person in range(size):
        pop[person][0]=0;let sampled=tgen_index(0);pop[person][1]=Int32(1 if sampled==0 else 1);pop[person][2]=0
    var fitness=InlineArray[Float64,8]();var best=InlineArray[Int32,3]();var best_distance:Float64=1.7976931348623157e308
    tgen_fitness(pop,size,x0,y0,x1,y1,fitness,best,best_distance)
    for _ in range(iterations):
        var total:Float64=0.0
        for i in range(size):total+=fitness[i]
        var probabilities=InlineArray[Float64,8]()
        for i in range(size):probabilities[i]=fitness[i]/total
        var selected=pop
        for person in range(size):
            var cumulative:Float64=0.0;let draw=tgen_unit()
            for candidate in range(size):
                cumulative+=probabilities[candidate]
                if draw<=cumulative:selected[person]=pop[candidate];break
        pop=selected
        let half=size/2
        for person in range(half):
            var first_child=pop[person];var second_child=pop[person+half]
            if tgen_unit()<=crossover:
                var first=tgen_index(2);var second=tgen_index(2)
                if first>second:let t=first;first=second;second=t
                for j in range(first,second+1):let t=first_child[j];first_child[j]=second_child[j];second_child[j]=t
                tgen_repair(first_child,first,second);tgen_repair(second_child,first,second)
            pop[person]=first_child;pop[person+half]=second_child
        for person in range(size):
            var chrom=pop[person]
            if tgen_unit()<=mutation:
                let first=tgen_index(0)+1;let second=tgen_index(0)+1
                let t=chrom[first];chrom[first]=chrom[second];chrom[second]=t
            pop[person]=chrom
        tgen_fitness(pop,size,x0,y0,x1,y1,fitness,best,best_distance)
    var staged=InlineArray[Float64,5]();staged[0]=3.0;staged[1]=Float64(best[0]);staged[2]=Float64(best[1]);staged[3]=Float64(best[2]);staged[4]=best_distance
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<5:return -2
    for i in range(5):o[i]=staged[i]
    return 5
