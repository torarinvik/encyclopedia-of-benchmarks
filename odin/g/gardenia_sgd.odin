// Clean-room bounded sequential GARDENIA MF-SGD profile.
package gardenia_sgd
import "core:c"
import "core:math"

@(export)
gardenia_sgd :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length<4||length>92 do return -1
	for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
	uv,iv,mv,kv:=input[0],input[1],input[2],input[3]
	if math.trunc(uv)!=uv||math.trunc(iv)!=iv||math.trunc(mv)!=mv||math.trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<1||mv>24||kv<1||kv>4 do return -1
	users,items,m,k:=int(uv),int(iv),int(mv),int(kv);n:=users+items;if n>8||int(length)!=5+users+2*m+n*k do return -1
	rp,ci,ra,la:=4,4+users+1,4+users+1+m,4+users+1+2*m
	var rows:[9]int;var cols:[24]int;var ratings:[24]f64;var latent:[32]f64;var errors:[8]f64;var staged:[32]f64
	for i:=0;i<=users;i+=1 { z:=input[rp+i];if math.trunc(z)!=z||z<0||z>f64(m) do return -1;rows[i]=int(z);if i>0&&rows[i]<rows[i-1] do return -1 }
	if rows[0]!=0||rows[users]!=m do return -1
	for e:=0;e<m;e+=1 { z:=input[ci+e];if math.trunc(z)!=z||z<0||z>=f64(items) do return -1;cols[e]=int(z);ratings[e]=input[ra+e];if ratings[e] < -4||ratings[e]>4 do return -1 }
	for q:=0;q<n*k;q+=1 { latent[q]=input[la+q];if latent[q]<0||latent[q]>0.1 do return -1 }
	required:=n*k;if output==nil||capacity<c.size_t(required) do return -2
	for iter:=0;iter<3;iter+=1 { for u:=0;u<users;u+=1 { errors[u]=0 };for u:=0;u<users;u+=1 { for e:=rows[u];e<rows[u+1];e+=1 { v:=users+cols[e];estimate:=0.0;for f:=0;f<k;f+=1 { estimate+=latent[u*k+f]*latent[v*k+f] };delta:=ratings[e]-estimate;errors[u]+=delta*delta;for f:=0;f<k;f+=1 { ui,vi:=u*k+f,v*k+f;pu,pi:=latent[ui],latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta) } } };total:=0.0;for u:=0;u<users;u+=1 { total+=errors[u] };if math.sqrt(total/f64(m))<0.1 { break } }
	for q:=0;q<required;q+=1 { staged[q]=latent[q] };for q:=0;q<required;q+=1 { output[q]=staged[q] };return i64(required)
}
