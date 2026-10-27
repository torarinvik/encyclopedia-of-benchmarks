// Clean-room fixed-embedding angle-assignment flow profile, DOI 653.
const N=8; const M=18; const F=12;
fn put64(out:[*]u8,index:usize,value:i64) void { const bits=@as(u64,@bitCast(value)); for(0..8)|b| out[index*8+b]=@truncate(bits>>(8*b)); }
const Match=struct { slots:[N]usize, terminals:[N]usize, incidence:[N][F]bool, owner:[N]i32, assigned:[N]i32,
 fn augment(self:*Match,t:usize,ns:usize,seen:*[N]bool) bool { for(0..ns)|s|{const f=self.slots[s];if(self.incidence[self.terminals[t]][f] and !seen[s]){seen[s]=true;const old=self.owner[s];if(old<0 or self.augment(@intCast(old),ns,seen)){self.owner[s]=@intCast(t);self.assigned[t]=@intCast(s);return true;}}}return false; }
};
fn suffix_match(first:usize,r:usize,f:usize,caps:[F]usize,terminals:[N]usize,incidence:[N][F]bool) bool {
 var mat=Match{.slots=undefined,.terminals=terminals,.incidence=incidence,.owner=[_]i32{-1}**N,.assigned=[_]i32{-1}**N};var ns:usize=0;for(0..f)|j|{for(0..caps[j])|_|{mat.slots[ns]=j;ns+=1;}}
 for(first..r)|i|{var seen=[_]bool{false}**N;if(!mat.augment(i,ns,&seen))return false;}return true;
}
export fn upward_planarity_angle_assignment(a:?[*]const i64,len:usize,output:?[*]u8,capacity:usize) callconv(.c) i64 {
 if(a==null or len<4 or len>124)return -1;const x=a.?;const nn=x[0];const mm=x[1];const ff=x[2];const oo=x[3];if(nn<2 or nn>8 or mm<1 or mm>18 or ff<1 or ff>12 or oo<0 or oo>=ff or len!=4+6*@as(usize,@intCast(mm))+@as(usize,@intCast(ff)))return -1;
 const n:usize=@intCast(nn);const m:usize=@intCast(mm);const f:usize=@intCast(ff);const outer:usize=@intCast(oo);
 var eu:[M]usize=undefined;var ev:[M]usize=undefined;var adj=[_] [N]bool{[_]bool{false}**N}**N;var oe=[_] [N]bool{[_]bool{false}**N}**N;var indeg=[_]usize{0}**N;
 for(0..m)|i|{const uu=x[4+2*i];const vv=x[5+2*i];if(uu<0 or uu>=nn or vv<0 or vv>=nn or uu==vv)return -1;const u:usize=@intCast(uu);const v:usize=@intCast(vv);if(i>0 and (eu[i-1]>u or (eu[i-1]==u and ev[i-1]>=v)))return -1;for(0..i)|j|{if((eu[j]==u and ev[j]==v)or(eu[j]==v and ev[j]==u))return -1;}eu[i]=u;ev[i]=v;adj[u][v]=true;adj[v][u]=true;oe[u][v]=true;indeg[v]+=1;}
 var wl=[_]usize{0}**F;var wu=[_]usize{0}**(2*M);var wv=[_]usize{0}**(2*M);var dart=[_][N]bool{[_]bool{false}**N}**N;var cursor:usize=4+2*m;var total:usize=0;
 for(0..f)|j|{const kk=x[cursor];cursor+=1;if(kk<1 or kk>2*@as(i64,@intCast(m)) or total+@as(usize,@intCast(kk))>2*m)return -1;const k:usize=@intCast(kk);wl[j]=k;for(0..k)|_|{const uu=x[cursor];const vv=x[cursor+1];cursor+=2;if(uu<0 or uu>=nn or vv<0 or vv>=nn)return -1;const u:usize=@intCast(uu);const v:usize=@intCast(vv);if(!adj[u][v] or dart[u][v])return -1;dart[u][v]=true;wu[total]=u;wv[total]=v;total+=1;}}
 if(cursor!=len or total!=2*m or @as(i64,@intCast(n))-mm+ff!=2)return -1;for(0..m)|i|{if(!dart[eu[i]][ev[i]] or !dart[ev[i]][eu[i]])return -1;}
 var succ=[_][N]i32{[_]i32{-1}**N}**N;var corner=[_][N]i32{[_]i32{-1}**N}**F;var incidence=[_][F]bool{[_]bool{false}**F}**N;var sw=[_][2]usize{[_]usize{0}**2}**F;cursor=0;
 for(0..f)|j|{const base=cursor;const k=wl[j];for(0..k)|i|{const u=wu[cursor];const v=wv[cursor];const w=wv[base+(i+1)%k];if(v!=wu[base+(i+1)%k] or succ[v][u]>=0)return -1;succ[v][u]=@intCast(w);if(corner[j][v]<0)corner[j][v]=@intCast(i);incidence[v][j]=true;if(oe[v][u] and oe[v][w])sw[j][0]+=1;if(!oe[v][u] and !oe[v][w])sw[j][1]+=1;cursor+=1;}}
 var visited=[_]bool{false}**N;var q=[_]usize{0}**N;var h:usize=0;var t:usize=1;q[0]=0;visited[0]=true;while(h<t){const u=q[h];h+=1;for(0..n)|v|{if(adj[u][v] and !visited[v]){visited[v]=true;q[t]=v;t+=1;}}}for(0..n)|v|{if(!visited[v])return -1;}
 var degree=indeg;h=0;t=0;for(0..n)|v|{if(degree[v]==0){q[t]=v;t+=1;}}var removed:usize=0;while(h<t){const u=q[h];h+=1;removed+=1;for(0..n)|v|{if(oe[u][v]){degree[v]-=1;if(degree[v]==0){q[t]=v;t+=1;}}}}if(removed!=n)return -1;
 for(0..n)|v|{var d:usize=0;for(0..n)|u|{if(adj[v][u])d+=1;}if(d>0){var start:usize=0;for(0..n)|u|{if(adj[v][u]){if(succ[v][u]<0)return -1;start=u;}}var cur=start;var count:usize=0;var transitions:usize=0;while(true){count+=1;if(count>d)return -1;const next:usize=@intCast(succ[v][cur]);if(oe[v][cur]!=oe[v][next])transitions+=1;cur=next;if(cur==start)break;}if(count!=d or (transitions!=0 and transitions!=2))return -1;}}
 var caps=[_]usize{0}**F;var sum:isize=0;var feasible=true;for(0..f)|j|{if(sw[j][0]!=sw[j][1])return -1;if(j==outer){caps[j]=sw[j][0]+1;}else if(sw[j][0]==0){feasible=false;}else{caps[j]=sw[j][0]-1;}sum+=@as(isize,@intCast(sw[j][0]))+if(j==outer)1 else -1;}
 var terminals=[_]usize{0}**N;var r:usize=0;for(0..n)|v|{var od:usize=0;for(0..n)|u|{if(oe[v][u])od+=1;}if(indeg[v]==0 or od==0){terminals[r]=v;r+=1;}}if(sum!=@as(isize,@intCast(r)))feasible=false;if(output==null or capacity<8*(2+3*r))return -2;
 var chosen=[_]i32{-1}**N;var ok=feasible;for(0..r)|i|{if(!ok)break;var found=false;for(0..f)|face|{if(incidence[terminals[i]][face] and caps[face]>0){caps[face]-=1;if(suffix_match(i+1,r,f,caps,terminals,incidence)){chosen[i]=@intCast(face);found=true;break;}caps[face]+=1;}}if(!found)ok=false;}
 var words=[_]i64{0}**26;words[0]=if(ok)1 else 0;words[1]=@intCast(r);var z:usize=2;for(0..r)|i|{if(ok){const face:usize=@intCast(chosen[i]);words[z]=@intCast(terminals[i]);words[z+1]=@intCast(face);words[z+2]=corner[face][terminals[i]];}else{words[z]=-1;words[z+1]=-1;words[z+2]=-1;}z+=3;}for(0..z)|i|put64(output.?,i,words[i]);return @intCast(z*8);
}
