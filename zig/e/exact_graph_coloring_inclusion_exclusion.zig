/// Exact chromatic number through independent-set inclusion-exclusion.
export fn exact_graph_coloring_inclusion_exclusion(x:?[*]const i64,length:usize,out:?[*]u8,cap:usize)i64{
 const a=x orelse return -2;if(length<2 or length>44)return -1;const nv=a[0];const mv=a[1];if(nv<1 or nv>7 or mv<0 or mv>21)return -1;
 const n:usize=@intCast(nv);const m:usize=@intCast(mv);if(length!=2+2*m)return -1;var adj:[7][7]bool=@splat(@splat(false));
 for(0..m)|e|{const u=a[2+2*e];const v=a[3+2*e];if(u<0 or v<0 or u>=nv or v>=nv or u==v)return -1;const uu:usize=@intCast(u);const vv:usize=@intCast(v);if(adj[uu][vv])return -1;adj[uu][vv]=true;adj[vv][uu]=true;}
 const lim:usize=@as(usize,1)<<@intCast(n);var cnt:[128]i64=@splat(0);cnt[0]=1;
 for(1..lim)|mask|{const bit=mask&(~mask+1);const v:usize=@ctz(bit);const rest=mask^bit;var allowed=rest;for(0..n)|u|if(adj[v][u]){allowed&=~(@as(usize,1)<<@intCast(u));};cnt[mask]=cnt[rest]+cnt[allowed];}
 var chi:i64=@intCast(n);for(1..n+1)|k|{var sum:i64=0;for(0..lim)|mask|{var term:i64=1;const base=cnt[mask]-1;for(0..k)|_|term*=base;const pc=@popCount(mask);sum+=if((n-pc)%2==0)term else -term;}if(sum>0){chi=@intCast(k);break;}}
 const output=out orelse return -2;if(cap<8)return -2;const raw=@as(u64,@intCast(chi));for(0..8)|i|output[i]=@truncate(raw>>(8*i));return 8;
}
