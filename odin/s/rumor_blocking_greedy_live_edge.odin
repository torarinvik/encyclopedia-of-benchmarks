package rumor_blocking_greedy_live_edge

import "core:c"

MAX_N :: 8
MAX_M :: 16
MAX_WORLDS :: 8

put_i64 :: proc "contextless" (output:[^]u8,word:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[word*8+b]=u8((bits>>(8*b))&255)}}

infected_count :: proc "contextless" (n,m,world:int,sources,protectors:u16,eu,ev,masks:[MAX_M]int)->int {
    status:[MAX_N]u8={};rf,pf:[MAX_N]bool={}
    for v:=0;v<n;v+=1 {if sources&(u16(1)<<v)!=0{status[v]=1;rf[v]=true};if protectors&(u16(1)<<v)!=0{status[v]=2;pf[v]=true}}
    for step:=0;step<n;step+=1 {
        rp,pp,nr,np:[MAX_N]bool={}
        for e:=0;e<m;e+=1 {u,v:=eu[e],ev[e];if status[v]!=0{continue};if pf[u]{pp[v]=true};if rf[u]&&(masks[e]&(1<<world))!=0{rp[v]=true}}
        changed:=false
        for v:=0;v<n;v+=1 {if status[v]!=0{continue};if pp[v]{status[v]=2;np[v]=true;changed=true}else if rp[v]{status[v]=1;nr[v]=true;changed=true}}
        rf,pf=nr,np;if !changed{break}
    }
    count:=0;for v:=0;v<n;v+=1{if status[v]==1{count+=1}};return count
}

@(export)
rumor_blocking_greedy_live_edge :: proc "c" (input:[^]i64,input_length:c.size_t,output:[^]u8,output_capacity:c.size_t)->i64 {
    if input==nil||input_length<5||input_length>61 do return -1
    n0,m0,r0,k0,w0:=input[0],input[1],input[2],input[3],input[4]
    if n0<2||n0>8||m0<0||m0>16||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>8||k0>n0-r0||input_length!=c.size_t(5+r0+3*m0) do return -1
    n,m,r,k,worlds:=int(n0),int(m0),int(r0),int(k0),int(w0);sources:u16=0
    for i:=0;i<r;i+=1 {v:=input[5+i];if v<0||v>=n0||sources&(u16(1)<<int(v))!=0 do return -1;sources|=u16(1)<<int(v)}
    eu,ev,masks:[MAX_M]int={};seen:[MAX_N][MAX_N]bool={};at:=5+r;allowed:=(1<<worlds)-1
    for e:=0;e<m;e+=1 {u,v,mask:=input[at+3*e],input[at+3*e+1],input[at+3*e+2];if u<0||u>=n0||v<0||v>=n0||u==v||mask<0||mask>i64(allowed) do return -1;if seen[int(u)][int(v)] do return -1;seen[int(u)][int(v)]=true;eu[e],ev[e],masks[e]=int(u),int(v),int(mask)}
    baseline:[MAX_WORLDS]int={};for w:=0;w<worlds;w+=1{baseline[w]=infected_count(n,m,w,sources,0,eu,ev,masks)}
    selected:u16=0;chosen,scores:[MAX_N]int={}
    for round:=0;round<k;round+=1 {
        current:[MAX_WORLDS]int={};for w:=0;w<worlds;w+=1{current[w]=baseline[w]-infected_count(n,m,w,sources,selected,eu,ev,masks)}
        best,best_score:=-1,-1
        for candidate:=0;candidate<n;candidate+=1 {bit:=u16(1)<<candidate;if sources&bit!=0||selected&bit!=0{continue};score:=0;for w:=0;w<worlds;w+=1{score+=baseline[w]-infected_count(n,m,w,sources,selected|bit,eu,ev,masks)-current[w]};if score>best_score{best,best_score=candidate,score}}
        if best<0 do return -1
        selected|=u16(1)<<best;chosen[round]=best;scores[round]=best_score
    }
    bytes:=c.size_t((1+2*k)*8);if output==nil||output_capacity<bytes do return -2
    put_i64(output,0,i64(k));for i:=0;i<k;i+=1{put_i64(output,1+2*i,i64(chosen[i]));put_i64(output,2+2*i,i64(scores[i]))};return i64(bytes)
}
