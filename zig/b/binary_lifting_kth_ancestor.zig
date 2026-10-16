const MAX_NODES:usize=256;const MAX_QUERIES:usize=1024;const LEVELS:usize=9;
fn put(out:[*]u8,slot:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|i|out[slot*8+i]=@truncate(bits>>@intCast(i*8));}
export fn binary_lifting_kth_ancestor(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<4)return -1;const n0=input[0];if(n0<1 or n0>MAX_NODES)return -1;const n:usize=@intCast(n0);if(input[1]<0 or input[1]>=n0 or input[2]!=n0-1 or input[3]<0 or input[3]>MAX_QUERIES)return -1;const m:usize=@intCast(input[2]);const q:usize=@intCast(input[3]);const qo=4+2*m;if(length!=qo+2*q)return -1;const root:usize=@intCast(input[1]);
 var adj:[MAX_NODES][MAX_NODES]bool=@splat(@splat(false));for(0..m)|e|{const a=input[4+2*e];const b=input[5+2*e];if(a<0 or b<0 or a>=n0 or b>=n0 or a==b)return -1;adj[@intCast(a)][@intCast(b)]=true;adj[@intCast(b)][@intCast(a)]=true;}
 for(0..q)|i|{const v=input[qo+2*i];const k=input[qo+2*i+1];if(v<0 or v>=n0 or k<0)return -1;}
 var up:[LEVELS][MAX_NODES]usize=@splat(@splat(0));var parent:[MAX_NODES]i64=@splat(-1);var stack:[MAX_NODES]usize=@splat(0);var top:usize=0;var reached:usize=0;parent[root]=@intCast(root);up[0][root]=root;stack[top]=root;top+=1;
 while(top>0){top-=1;const u=stack[top];reached+=1;for(0..n)|v|{if(adj[u][v]){if(@as(i64,@intCast(v))==parent[u])continue;if(parent[v]!=-1)return -1;parent[v]=@intCast(u);up[0][v]=u;stack[top]=v;top+=1;}}}if(reached!=n)return -1;
 for(1..LEVELS)|level|{for(0..n)|v|{up[level][v]=up[level-1][up[level-1][v]];}}
 const bytes=(1+q)*8;if(output==null or capacity<bytes)return -2;put(output,0,@intCast(q));for(0..q)|i|{var v:usize=@intCast(input[qo+2*i]);const k:u64=@intCast(input[qo+2*i+1]);if(k>=n)v=root else{for(0..LEVELS)|bit|{if(k&(@as(u64,1)<<@intCast(bit))!=0)v=up[bit][v];}}put(output,1+i,@intCast(v));}return @intCast(bytes);
}
