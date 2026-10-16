const max_n: usize = 32;
const max_q: i64 = 128;
fn findRoot(parent: *[max_n]usize, x0: usize) usize { var x=x0;while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];}return x; }
fn sideNodes(adj: *[max_n]u64,n:usize,start:usize,out:*[max_n]usize) usize {
 var seen:[max_n]bool=@splat(false);var stack:[max_n]usize=undefined;var top:usize=0;var count:usize=0;stack[top]=start;top+=1;
 while(top>0){top-=1;const u=stack[top];if(seen[u])continue;seen[u]=true;out[count]=u;count+=1;for (0..n)|v|{if(((adj[u]>>@intCast(v))&1)!=0 and !seen[v]){stack[top]=v;top+=1;}}}return count;
}
pub export fn decremental_connectivity(a:[*]const i64,length:usize)i64 {
 if(length<3 or length>449)return -1;const n64=a[0];const m64=a[1];if(n64<1 or n64>32 or m64<0 or m64>=n64)return -1;const n:usize=@intCast(n64);const m:usize=@intCast(m64);const ep=2+2*m;if(length<=ep)return -1;const q64=a[ep];if(q64<0 or q64>max_q or length!=ep+1+3*@as(usize,@intCast(q64)))return -1;const q:usize=@intCast(q64);
 var adj:[max_n]u64=@splat(0);var parent:[max_n]usize=undefined;for (0..n)|i|{parent[i]=i;}
 for (0..m)|i|{const u_input=a[2+2*i];const v_input=a[3+2*i];if(u_input<0 or u_input>=n64 or v_input<0 or v_input>=n64 or u_input==v_input)return -1;const u:usize=@intCast(u_input);const v:usize=@intCast(v_input);if(((adj[u]>>@intCast(v))&1)!=0)return -1;const ru=findRoot(&parent,u);const rv=findRoot(&parent,v);if(ru==rv)return -1;parent[rv]=ru;adj[u]|=@as(u64,1)<<@intCast(v);adj[v]|=@as(u64,1)<<@intCast(u);}
 var comp:[max_n]usize=@splat(max_n);var next:usize=0;var stack:[max_n]usize=undefined;
 for (0..n)|start|{if(comp[start]!=max_n)continue;var top:usize=0;stack[top]=start;top+=1;comp[start]=next;while(top>0){top-=1;const u=stack[top];for (0..n)|v|{if(((adj[u]>>@intCast(v))&1)!=0 and comp[v]==max_n){comp[v]=next;stack[top]=v;top+=1;}}}next+=1;}
 var h:u64=14695981039346656037;for (0..q)|k|{const p=ep+1+3*k;const op=a[p];const u_input=a[p+1];const v_input=a[p+2];if((op!=0 and op!=1) or u_input<0 or u_input>=n64 or v_input<0 or v_input>=n64)return -1;const u:usize=@intCast(u_input);const v:usize=@intCast(v_input);if(op==1){h=(h^@as(u64,@intFromBool(comp[u]==comp[v])))*%1099511628211;continue;}if(((adj[u]>>@intCast(v))&1)==0 or comp[u]!=comp[v])return -1;adj[u]&=~(@as(u64,1)<<@intCast(v));adj[v]&=~(@as(u64,1)<<@intCast(u));var left:[max_n]usize=undefined;var right:[max_n]usize=undefined;const lc=sideNodes(&adj,n,u,&left);const rc=sideNodes(&adj,n,v,&right);if(lc<rc or (lc==rc and u<v)){for (0..lc)|j|{comp[left[j]]=next;}}else{for (0..rc)|j|{comp[right[j]]=next;}}next+=1;}
 return @bitCast(h);
}
