/// Layered edit-distance shortest paths over a supplied literal NFA.
export fn approximate_regex_matching(x: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const a=x orelse return -2;
    if(length<6 or length>66)return -1;
    const sv=a[0];const ev=a[1];const tv=a[2];const kv=a[3];const startv=a[4];const acceptv=a[5];
    if(sv<2 or sv>8 or ev<1 or ev>16 or tv<0 or tv>12 or kv<0 or kv>3 or startv<0 or acceptv<0 or startv>=sv or acceptv>=sv or startv==acceptv)return -1;
    const s:usize=@intCast(sv);const e:usize=@intCast(ev);const t:usize=@intCast(tv);const k:usize=@intCast(kv);const start:usize=@intCast(startv);const accept:usize=@intCast(acceptv);const ts=6+3*e;
    if(length!=ts+t)return -1;
    var from:[16]usize=@splat(0);var to:[16]usize=@splat(0);var label:[16]u8=@splat(0);
    for(0..e)|i|{const u=a[6+3*i];const v=a[7+3*i];const c=a[8+3*i];if(u<0 or u>=sv or v<0 or v>=sv or c<1 or c>127)return -1;
        from[i]=@intCast(u);to[i]=@intCast(v);label[i]=@intCast(c);for(0..i)|j|if(from[i]==from[j] and to[i]==to[j] and label[i]==label[j])return -1;}
    for(0..t)|i|if(a[ts+i]<1 or a[ts+i]>127)return -1;
    const out=output orelse {
        if (t == 0) return 0;
        return -2;
    };
    if(capacity<t)return -2;
    const inf:i64=@intCast(k+1);var cur:[8]i64=@splat(inf);var next:[8]i64=@splat(inf);
    for(0..t)|pos|{cur[start]=0;
        for(0..s-1)|_|{var changed=false;for(0..e)|i|if(cur[from[i]]<inf and cur[from[i]]+1<cur[to[i]]){cur[to[i]]=cur[from[i]]+1;changed=true;};if(!changed)break;}
        for(0..s)|q|next[q]=if(cur[q]<inf)cur[q]+1 else inf;
        for(0..e)|i|if(cur[from[i]]<inf){const cost=cur[from[i]]+@as(i64,if(label[i]!=a[ts+pos])1 else 0);if(cost<next[to[i]])next[to[i]]=cost;};
        for(0..s-1)|_|{var changed=false;for(0..e)|i|if(next[from[i]]<inf and next[from[i]]+1<next[to[i]]){next[to[i]]=next[from[i]]+1;changed=true;};if(!changed)break;}
        out[pos]=if(next[accept]<=@as(i64,@intCast(k)))1 else 0;cur=next;
    }
    return @intCast(t);
}
