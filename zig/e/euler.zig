export fn euler(v:?[*]const i64,n:usize)i64{
 if(v==null or n<4 or n>516)return -2;const a=v.?;const count=a[0];const source=a[1];const dest=a[2];const edges=a[3];
 if(count<1 or count>32 or source<0 or source>=count or dest<0 or dest>=count or edges<0 or edges>256 or n!=4+2*@as(usize,@intCast(edges)))return -2;
 var adj=[_]u64{0}**32;var degree=[_]i64{0}**32;
 for(0..@intCast(edges))|i|{const x=a[4+2*i];const y=a[5+2*i];if(x<0 or y<0 or x>=count or y>=count or x==y)return -2;const xi:usize=@intCast(x);const yi:usize=@intCast(y);const bx:u64=@as(u64,1)<<@intCast(x);const by:u64=@as(u64,1)<<@intCast(y);if(adj[xi]&by!=0)return -2;adj[xi]|=by;adj[yi]|=bx;degree[xi]+=1;degree[yi]+=1;}
 var odd:i64=0;for(0..@intCast(count))|i|{const want=source!=dest and (@as(i64,@intCast(i))==source or @as(i64,@intCast(i))==dest);const is_odd=degree[i]%2!=0;if(is_odd!=want)return 0;if(is_odd)odd+=1;}
 if(source==dest)return if(odd==0)1 else 0;return if(odd==2)1 else 0;
}
