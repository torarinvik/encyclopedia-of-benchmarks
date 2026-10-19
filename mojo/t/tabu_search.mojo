from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ts_cost(route:InlineArray[Int32,7],len:Int,edge:InlineArray[Int64,36])->Int64:
    var cost:Int64=0
    for i in range(len-1):cost+=edge[Int(route[i])*6+Int(route[i+1])]
    return cost
fn ts_same(a:InlineArray[Int32,7],b:InlineArray[Int32,7],len:Int)->Bool:
    for i in range(len):if a[i]!=b[i]:return False
    return True
@export("tabu_search")
fn tabu_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>19:return -1
    let cities=a[0];let iterations=a[1];let tabu_size=a[2]
    if cities<4 or cities>6 or iterations<0 or iterations>8 or tabu_size<1 or tabu_size>3 or n!=c_size_t(3+cities*(cities-1)/2):return -1
    var edge=InlineArray[Int64,36]();var at=3
    for i in range(Int(cities)):for j in range(i+1,Int(cities)):
        let w=a[at];at+=1
        if w<1 or w>99:return -1
        edge[i*6+j]=w;edge[j*6+i]=w
    var route=InlineArray[Int32,7]();var route_len=0;var current=0
    while True:
        var visited=false
        for i in range(route_len):if route[i]==current:visited=true
        if visited:break
        var minimum:Int64=10000;var best=current
        for node in range(Int(cities)):
            var used=false
            for i in range(route_len):if route[i]==node:used=true
            if node!=current and not used and edge[current*6+node]<minimum:minimum=edge[current*6+node];best=node
        route[route_len]=Int32(current);route_len+=1;current=best
    route[route_len]=0;route_len+=1
    var best_cost=ts_cost(route,route_len,edge);var best_route=route
    var tabu_new=InlineArray[Int32,3]();var tabu_old=InlineArray[Int32,3]();var tabu_count=0
    for _ in range(Int(iterations)):
        var candidates=InlineArray[InlineArray[Int32,7],10]();var costs=InlineArray[Int64,10]();var cc=0
        for x in range(1,route_len-1):for y in range(1,route_len-1):
            if x==y:continue
            var candidate=route;let t=candidate[x];candidate[x]=candidate[y];candidate[y]=t
            var duplicate=false
            for j in range(cc):if ts_same(candidate,candidates[j],route_len):duplicate=true
            if not duplicate:candidates[cc]=candidate;costs[cc]=ts_cost(candidate,route_len,edge);cc+=1
        for i in range(1,cc):
            let cand=candidates[i];let cost=costs[i];var j=i
            while j>0 and cost<costs[j-1]:candidates[j]=candidates[j-1];costs[j]=costs[j-1];j-=1
            candidates[j]=cand;costs[j]=cost
        var selected=0
        while selected<cc:
            var diff=0
            while diff<route_len and candidates[selected][diff]==route[diff]:diff+=1
            let new=candidates[selected][diff];let old=route[diff];var forbidden=false
            for j in range(tabu_count):if (tabu_new[j]==new and tabu_old[j]==old) or (tabu_new[j]==old and tabu_old[j]==new):forbidden=true
            if not forbidden:break
            selected+=1
        if selected>=cc:return -1
        var diff=0
        while diff<route_len and candidates[selected][diff]==route[diff]:diff+=1
        tabu_new[tabu_count]=candidates[selected][diff];tabu_old[tabu_count]=route[diff];tabu_count+=1
        route=candidates[selected]
        if costs[selected]<best_cost:best_cost=costs[selected];best_route=route
        if tabu_count>=Int(tabu_size):
            for j in range(1,tabu_count):tabu_new[j-1]=tabu_new[j];tabu_old[j-1]=tabu_old[j]
            tabu_count-=1
    let bytes=(route_len+2)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[Int32,9]();staged[0]=Int32(route_len)
    for i in range(route_len):staged[i+1]=best_route[i]
    staged[route_len+1]=Int32(best_cost)
    for i in range(route_len+2):let bits=bitcast[UInt32](staged[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
