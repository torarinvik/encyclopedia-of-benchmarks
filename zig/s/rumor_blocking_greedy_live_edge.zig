const MAX_N: usize=8;const MAX_M:usize=16;const MAX_WORLDS:usize=8;
fn infectedCount(n:usize,m:usize,world:usize,sources:u16,protectors:u16,eu:[MAX_M]usize,ev:[MAX_M]usize,masks:[MAX_M]u16)i64{
    var status=[_]u8{0}**MAX_N;var rf=[_]bool{false}**MAX_N;var pf=[_]bool{false}**MAX_N;
    for(0..n)|v|{if(sources&(@as(u16,1)<<@intCast(v))!=0){status[v]=1;rf[v]=true;}if(protectors&(@as(u16,1)<<@intCast(v))!=0){status[v]=2;pf[v]=true;}}
    for(0..n)|_|{var rp=[_]bool{false}**MAX_N;var pp=[_]bool{false}**MAX_N;
        for(0..m)|e|{const u=eu[e];const v=ev[e];if(status[v]!=0)continue;if(pf[u])pp[v]=true;if(rf[u]&&(masks[e]&(@as(u16,1)<<@intCast(world)))!=0)rp[v]=true;}
        var nr=[_]bool{false}**MAX_N;var np=[_]bool{false}**MAX_N;var changed=false;
        for(0..n)|v|{if(status[v]!=0)continue;if(pp[v]){status[v]=2;np[v]=true;changed=true;}else if(rp[v]){status[v]=1;nr[v]=true;changed=true;}}
        rf=nr;pf=np;if(!changed)break;
    }
    var count:i64=0;for(0..n)|v|{if(status[v]==1)count+=1;}return count;
}
fn putI64(output:[*c]u8,word:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|output[word*8+b]=@truncate(bits>>@intCast(8*b));}

export fn rumor_blocking_greedy_live_edge(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null||length<5||length>61)return -1;const n0=input[0];const m0=input[1];const r0=input[2];const k0=input[3];const w0=input[4];
    if(n0<2||n0>8||m0<0||m0>16||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>8||k0>n0-r0||length!=5+@as(usize,@intCast(r0))+3*@as(usize,@intCast(m0)))return -1;
    const n:usize=@intCast(n0);const m:usize=@intCast(m0);const r:usize=@intCast(r0);const k:usize=@intCast(k0);const worlds:usize=@intCast(w0);var sources:u16=0;
    for(0..r)|i|{const v=input[5+i];if(v<0||v>=n0)return -1;const bit:u16=@as(u16,1)<<@intCast(v);if(sources&bit!=0)return -1;sources|=bit;}
    var eu=[_]usize{0}**MAX_M;var ev=[_]usize{0}**MAX_M;var masks=[_]u16{0}**MAX_M;var seen=[_]bool{false}**(MAX_N*MAX_N);const at=5+r;const allowed=(1<<worlds)-1;
    for(0..m)|e|{const u=input[at+3*e];const v=input[at+3*e+1];const mask=input[at+3*e+2];if(u<0||u>=n0||v<0||v>=n0||u==v||mask<0||mask>allowed)return -1;const key=@as(usize,@intCast(u))*MAX_N+@as(usize,@intCast(v));if(seen[key])return -1;seen[key]=true;eu[e]=@intCast(u);ev[e]=@intCast(v);masks[e]=@intCast(mask);}
    var baseline=[_]i64{0}**MAX_WORLDS;for(0..worlds)|w|baseline[w]=infectedCount(n,m,w,sources,0,eu,ev,masks);
    var selected:u16=0;var chosen=[_]i64{0}**MAX_N;var scores=[_]i64{0}**MAX_N;
    for(0..k)|round|{var current=[_]i64{0}**MAX_WORLDS;for(0..worlds)|w|current[w]=baseline[w]-infectedCount(n,m,w,sources,selected,eu,ev,masks);var best:i64=-1;var best_score:i64=-1;
        for(0..n)|candidate|{const bit:u16=@as(u16,1)<<@intCast(candidate);if(sources&bit!=0||selected&bit!=0)continue;var score:i64=0;for(0..worlds)|w|score+=baseline[w]-infectedCount(n,m,w,sources,selected|bit,eu,ev,masks)-current[w];if(score>best_score){best=@intCast(candidate);best_score=score;}}
        if(best<0)return -1;const bit:u16=@as(u16,1)<<@intCast(best);selected|=bit;chosen[round]=best;scores[round]=best_score;
    }
    const bytes=(1+2*k)*8;if(output==null||capacity<bytes)return -2;putI64(output,0,@intCast(k));for(0..k)|i|{putI64(output,1+2*i,chosen[i]);putI64(output,2+2*i,scores[i]);}return @intCast(bytes);
}
