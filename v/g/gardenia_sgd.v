// Clean-room bounded sequential GARDENIA MF-SGD profile.
import math

@[export: 'gardenia_sgd']
pub fn gardenia_sgd(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length<4||length>92{return -1}
		for q in 0..length{if !input[q].is_finite(){return -1}}
		uv,iv,mv,kv:=input[0],input[1],input[2],input[3]
		if math.trunc(uv)!=uv||math.trunc(iv)!=iv||math.trunc(mv)!=mv||math.trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<1||mv>24||kv<1||kv>4{return -1}
		users,items,m,k:=int(uv),int(iv),int(mv),int(kv);n:=users+items;if n>8||length!=usize(5+users+2*m+n*k){return -1}
		rp,ci,ra,la:=4,4+users+1,4+users+1+m,4+users+1+2*m
		mut rows:=[9]int{};mut cols:=[24]int{};mut ratings:=[24]f64{};mut latent:=[32]f64{};mut errors:=[8]f64{};mut staged:=[32]f64{}
		for i in 0..users+1{z:=input[rp+i];if math.trunc(z)!=z||z<0||z>f64(m){return -1};rows[i]=int(z);if i>0&&rows[i]<rows[i-1]{return -1}}
		if rows[0]!=0||rows[users]!=m{return -1}
		for e in 0..m{z:=input[ci+e];if math.trunc(z)!=z||z<0||z>=f64(items){return -1};cols[e]=int(z);ratings[e]=input[ra+e];if ratings[e] < -4||ratings[e]>4{return -1}}
		for q in 0..n*k{latent[q]=input[la+q];if latent[q]<0||latent[q]>0.1{return -1}}
		required:=n*k;if output==nil||capacity<usize(required){return -2}
		for _ in 0..3{for u in 0..users{errors[u]=0};for u in 0..users{for e in rows[u]..rows[u+1]{v:=users+cols[e];mut estimate:=0.0;for f in 0..k{estimate+=latent[u*k+f]*latent[v*k+f]};delta:=ratings[e]-estimate;errors[u]+=delta*delta;for f in 0..k{ui,vi:=u*k+f,v*k+f;pu,pi:=latent[ui],latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta)}}};mut total:=0.0;for u in 0..users{total+=errors[u]};if math.sqrt(total/f64(m))<0.1{break}}
		for q in 0..required{staged[q]=latent[q]};for q in 0..required{output[q]=staged[q]};return i64(required)
	}
}
