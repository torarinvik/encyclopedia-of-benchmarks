package global_minimum_cut_of_dynamic_star_augmented_graph
import "core:c"
MAX_N::16;MAX_M::64;MAX_Q::32;MAX_V::17;MAX_INPUT::276;MAX_OUTPUT::256;MAX_W::i64(1000000)
store_le::proc(out:[^]u8,at:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8}}
stoer_wagner::proc(n:int,spokes:[MAX_N]i64,m:int,eu:[MAX_M]i64,ev:[MAX_M]i64,ew:[MAX_M]i64)->i64{
	vc:=n+1;w:[MAX_V][MAX_V]i64={};for e:=0;e<m;e+=1{u:=int(eu[e]);v:=int(ev[e]);w[u][v]+=ew[e];w[v][u]+=ew[e]};for u:=0;u<n;u+=1{w[u][n]+=spokes[u];w[n][u]+=spokes[u]}
	active:[MAX_V]int={};count:=vc;for i:=0;i<vc;i+=1{active[i]=i};best:=i64(0x7fffffffffffffff)
	for count>1{used:[MAX_V]bool={};connection:[MAX_V]i64={};previous:=-1
		for step:=0;step<count;step+=1{selected:=-1;for z:=0;z<count;z+=1{u:=active[z];if !used[u]&&(selected<0||connection[u]>connection[selected]||(connection[u]==connection[selected]&&u<selected)){selected=u}}
			if step+1==count{if connection[selected]<best{best=connection[selected]};for z:=0;z<count;z+=1{u:=active[z];if u!=selected&&u!=previous{w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u]}};pos:=0;for active[pos]!=selected{pos+=1};for z:=pos+1;z<count;z+=1{active[z-1]=active[z]};count-=1;break}
			used[selected]=true;previous=selected;for z:=0;z<count;z+=1{u:=active[z];if !used[u]{connection[u]+=w[selected][u]}}
		}
	};return best
}
@(export)
global_minimum_cut_of_dynamic_star_augmented_graph::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<3||length>MAX_INPUT do return -1;n0,m0,q0:=input[0],input[1],input[2];if n0<1||n0>MAX_N||m0<0||m0>MAX_M||m0>n0*(n0-1)/2||q0<1||q0>MAX_Q do return -1
	n,m,q:=int(n0),int(m0),int(q0);if length!=c.size_t(3+n+3*m+2*q) do return -1;pos:=3
	spokes:[MAX_N]i64={};for i:=0;i<n;i+=1{spokes[i]=input[pos];pos+=1;if spokes[i]<0||spokes[i]>MAX_W do return -1}
	eu,ev,ew:[MAX_M]i64={},{},{};seen:[MAX_N][MAX_N]bool={}
	for e:=0;e<m;e+=1{u,v,weight:=input[pos],input[pos+1],input[pos+2];pos+=3;if u<0||u>=n0||v<0||v>=n0||u==v||weight<0||weight>MAX_W do return -1;a,b:=int(min(u,v)),int(max(u,v));if seen[a][b] do return -1;seen[a][b]=true;eu[e]=u;ev[e]=v;ew[e]=weight}
	ux,uy:[MAX_Q]i64={},{};for i:=0;i<q;i+=1{ux[i]=input[pos];uy[i]=input[pos+1];pos+=2;if ux[i]<0||ux[i]>=n0||uy[i]<0||uy[i]>MAX_W do return -1}
	bytes:=8*q;if bytes>MAX_OUTPUT do return -1;if output==nil||capacity<c.size_t(bytes) do return -2
	answers:[MAX_Q]i64={};for i:=0;i<q;i+=1{spokes[int(ux[i])]=uy[i];answers[i]=stoer_wagner(n,spokes,m,eu,ev,ew)};for i:=0;i<q;i+=1{store_le(output,8*i,answers[i])};return i64(bytes)
}
