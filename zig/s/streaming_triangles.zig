fn power(base:i64,exp:usize)i64{var r:i64=1;for(0..exp)|_|{r*=base;}return r;}
fn put_i64(out:[*c]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
fn make_wedge(a:[2]i64,b:[2]i64,out:*[2]i64)bool{
    var c:i64=-1;for(a)|x|{for(b)|y|{if(x==y)c=x;}}
    if(c<0)return false;var x=if(a[0]==c)a[1]else a[0];var y=if(b[0]==c)b[1]else b[0];if(x==y)return false;if(x>y){const z=x;x=y;y=z;}out.*=.{x,y};return true;
}

export fn streaming_triangles(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<10 or length>340)return -1;const n0=input[0];const m0=input[1];const se0=input[2];const sw0=input[3];
    if(n0<2 or n0>8 or m0<1 or m0>28 or se0<2 or se0>4 or sw0<1 or sw0>4)return -1;
    const m:usize=@intCast(m0);const se:usize=@intCast(se0);const sw:usize=@intCast(sw0);const stride=2+2*sw;if(length!=4+2*m+m*stride)return -1;
    var eu=[_]i64{0}**28;var ev=[_]i64{0}**28;var seen=[_]bool{false}**64;
    for(0..m)|i|{const u=input[4+2*i];const v=input[5+2*i];if(u<0 or v<=u or v>=n0)return -1;const ui:usize=@intCast(u);const vi:usize=@intCast(v);const key=ui*8+vi;if(seen[key])return -1;seen[key]=true;seen[vi*8+ui]=true;eu[i]=u;ev[i]=v;}
    var edge_res=[_]i32{-1}**4;var wu=[_]i64{0}**4;var wv=[_]i64{0}**4;var wvalid=[_]bool{false}**4;var closed=[_]bool{false}**4;
    var total:i64=0;var staged=[_]i64{0}**84;var at:usize=0;const tape=4+2*m;
    for(0..m)|ti|{const t=ti+1;const rec=tape+ti*stride;
        for(0..sw)|s|{if(wvalid[s] and wu[s]==eu[ti] and wv[s]==ev[ti])closed[s]=true;}
        const draw=input[rec];const slot0=input[rec+1];const limit=power(@intCast(t),se);const threshold=limit-power(@intCast(t-1),se);if(draw<0 or draw>=limit)return -1;const update=draw<threshold;
        var fresh_u=[_]i64{0}**4;var fresh_v=[_]i64{0}**4;var fresh_count:usize=0;var removed_count:usize=0;
        if(update){if(slot0<0 or slot0>=@as(i64,@intCast(se)))return -1;const slot:usize=@intCast(slot0);const old_id=edge_res[slot];if(old_id>=0){const oi:usize=@intCast(old_id);for(0..se)|j|{if(j!=slot and edge_res[j]>=0){const old:usize=@intCast(edge_res[j]);var old_w=[_]i64{0}**2;if(make_wedge(.{eu[oi],ev[oi]},.{eu[old],ev[old]},&old_w))removed_count+=1;}}}edge_res[slot]=@intCast(ti);for(0..se)|j|{if(j!=slot and edge_res[j]>=0){const old:usize=@intCast(edge_res[j]);var out=[_]i64{0}**2;if(make_wedge(.{eu[ti],ev[ti]},.{eu[old],ev[old]},&out)){fresh_u[fresh_count]=out[0];fresh_v[fresh_count]=out[1];fresh_count+=1;}}}}else if(slot0!=0)return -1;
        total+=@as(i64,@intCast(fresh_count))-@as(i64,@intCast(removed_count));if(total<0)return -1;
        for(0..sw)|s|{const wd=input[rec+2+2*s];const pick=input[rec+3+2*s];if(fresh_count>0){if(wd<0 or wd>=total)return -1;if(wd<@as(i64,@intCast(fresh_count))){if(pick<0 or pick>=@as(i64,@intCast(fresh_count)))return -1;const p:usize=@intCast(pick);wu[s]=fresh_u[p];wv[s]=fresh_v[p];wvalid[s]=true;closed[s]=false;}else if(pick!=0)return -1;}else if(wd!=0 or pick!=0)return -1;}
        var hits:i64=0;for(0..sw)|s|{if(closed[s])hits+=1;}staged[at]=total;staged[at+1]=(3*hits*1_000_000)/@as(i64,@intCast(sw));staged[at+2]=(hits*@as(i64,@intCast(t))*@as(i64,@intCast(t))*total*1_000_000)/@as(i64,@intCast(sw*se*(se-1)));at+=3;
    }
    const bytes=24*m;if(output==null or capacity<bytes)return -2;for(0..at)|i|put_i64(output,8*i,staged[i]);return @intCast(bytes);
}
