from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn zpg_attractor(active:Int64,player:Int,target:Int64,owners:InlineArray[Int64,8],adjacency:InlineArray[Int64,8],n:Int)->Int64:
    var attracted=target
    while True:
        var additions:Int64=0
        for vertex in range(n):
            let bit=Int64(1)<<vertex
            if active&bit==0 or attracted&bit!=0:continue
            let successors=adjacency[vertex]&active
            if owners[vertex]==player:
                if successors&attracted!=0:additions|=bit
            elif successors!=0 and successors&(~attracted)==0:additions|=bit
        if additions==0:return attracted
        attracted|=additions

fn zpg_solve(active:Int64,owners:InlineArray[Int64,8],priorities:InlineArray[Int64,8],adjacency:InlineArray[Int64,8],n:Int)->Int64:
    if active==0:return 0
    var lowest:Int64=6
    for vertex in range(n):
        if active&(Int64(1)<<vertex)!=0 and priorities[vertex]<lowest:lowest=priorities[vertex]
    let player=Int(lowest&1)
    var target:Int64=0
    for vertex in range(n):
        if active&(Int64(1)<<vertex)!=0 and priorities[vertex]==lowest:target|=Int64(1)<<vertex
    let first=zpg_attractor(active,player,target,owners,adjacency,n)
    let remainder=active&(~first)
    let even_first=zpg_solve(remainder,owners,priorities,adjacency,n)
    let odd_first=remainder&(~even_first)
    let opponent_region=even_first if player==1 else odd_first
    if opponent_region==0:return even_first|(first if player==0 else 0)
    let second=zpg_attractor(active,1-player,opponent_region,owners,adjacency,n)
    let even_second=zpg_solve(active&(~second),owners,priorities,adjacency,n)
    return even_second|(second if player==1 else 0)

fn zpg_impl(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t)->Int64:
    if length<6 or length>59:return -1
    let vertex_raw=input[0];let edge_raw=input[1]
    if vertex_raw<1 or vertex_raw>8 or edge_raw<vertex_raw or edge_raw>20:return -1
    let n=Int(vertex_raw);let edge_count=Int(edge_raw)
    if length!=c_size_t(2+2*n+2*edge_count):return -1
    var owners=InlineArray[Int64,8](fill=0)
    var priorities=InlineArray[Int64,8](fill=0)
    var adjacency=InlineArray[Int64,8](fill=0)
    var outdegree=InlineArray[Int,8](fill=0)
    var cursor=2
    for vertex in range(n):
        let owner=input[cursor];let priority=input[cursor+1];cursor+=2
        if owner<0 or owner>1 or priority<0 or priority>5:return -1
        owners[vertex]=owner;priorities[vertex]=priority
    for _ in range(edge_count):
        let source_raw=input[cursor];let destination_raw=input[cursor+1];cursor+=2
        if source_raw<0 or source_raw>=vertex_raw or destination_raw<0 or destination_raw>=vertex_raw:return -1
        let source=Int(source_raw);let destination=Int(destination_raw);let bit=Int64(1)<<destination
        if adjacency[source]&bit!=0:return -1
        adjacency[source]|=bit;outdegree[source]+=1
    for vertex in range(n):
        if outdegree[vertex]==0:return -1
    return zpg_solve((Int64(1)<<n)-1,owners,priorities,adjacency,n)

@export("zielonka_parity_game_solver")
fn zielonka_parity_game_solver(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<6 or length>59:return -1
    return zpg_impl(input,length)
