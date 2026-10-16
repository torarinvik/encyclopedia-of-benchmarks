const max_n: usize = 16;
fn mix(h0: u64, x0: u64) u64 { var h=h0;var x=x0;for(0..8)|_|{h=(h^(x&255))*%1099511628211;x>>=8;}return h; }
pub export fn deep_clone_graph(a: [*]const i64, length: usize) i64 {
 if(length<4 or length>34)return -1;const n64=a[0];const root64=a[1];if(n64<1 or n64>16 or root64<0 or root64>=n64 or length!=2+2*@as(usize,@intCast(n64)))return -1;
 const n:usize=@intCast(n64);const root:usize=@intCast(root64);var labels:[max_n]i64=@splat(0);var masks:[max_n]u64=@splat(0);var copied:[max_n]u64=@splat(0);var seen:[max_n]bool=@splat(false);var stack:[256]usize=undefined;var top:usize=0;var count:u64=0;
 for(0..n)|i|{const value=a[2+i];const row=a[2+n+i];if(value < -2147483648 or value > 2147483647 or row<0 or (@as(u64,@intCast(row))>>@intCast(n))!=0)return -1;labels[i]=value;masks[i]=@intCast(row);}
 for(0..n)|i|{for(0..n)|j|{if(((masks[i]>>@intCast(j))&1)!=((masks[j]>>@intCast(i))&1))return -1;}}
 stack[top]=root;top+=1;while(top>0){top-=1;const u=stack[top];if(seen[u])continue;seen[u]=true;count+=1;copied[u]=masks[u];for(0..n)|v|{if(((masks[u]>>@intCast(v))&1)!=0 and !seen[v]){stack[top]=v;top+=1;}}}
 var h=mix(14695981039346656037,count);h=mix(h,@bitCast(root64));for(0..n)|i|{if(seen[i]){h=mix(h,@bitCast(labels[i]));h=mix(h,copied[i]);}}return @bitCast(h);
}
