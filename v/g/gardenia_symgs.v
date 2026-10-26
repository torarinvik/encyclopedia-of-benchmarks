// Clean-room bounded GARDENIA SymGS profile.
import math

@[export: 'gardenia_symgs']
pub fn gardenia_symgs(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length<3||length>173{return -1}
		for q in 0..length { if !input[q].is_finite(){return -1} }
		nd,md,cd:=input[0],input[1],input[2]
		if math.trunc(nd)!=nd||math.trunc(md)!=md||math.trunc(cd)!=cd||nd<1||nd>8||md<1||md>64||cd<1||cd>nd{return -1}
		n,m,colors:=int(nd),int(md),int(cd);if length!=usize(5+4*n+colors+2*m){return -1}
		oa,fa,ra,ca,va,xa,ba:=3,3+n,3+n+colors+1,3+n+colors+1+n+1,3+n+colors+1+n+1+m,3+n+colors+1+n+1+2*m,3+n+colors+1+n+1+2*m+n
		mut order:=[8]int{};mut offsets:=[9]int{};mut rows:=[9]int{};mut cols:=[64]int{};mut group:=[8]int{}
		mut mat:=[64]f64{};mut x:=[8]f64{};mut rhs:=[8]f64{};mut staged:=[8]f64{};mut seen:=[8]bool{}
		for i in 0..n { z:=input[oa+i];if math.trunc(z)!=z||z<0||z>=nd||seen[int(z)]{return -1};order[i]=int(z);seen[order[i]]=true }
		for k in 0..colors+1 { z:=input[fa+k];if math.trunc(z)!=z||z<0||z>nd{return -1};offsets[k]=int(z) }
		if offsets[0]!=0||offsets[colors]!=n{return -1}
		for k in 0..colors { if offsets[k]>=offsets[k+1]{return -1};for p in offsets[k]..offsets[k+1]{group[order[p]]=k} }
		for i in 0..n+1 { z:=input[ra+i];if math.trunc(z)!=z||z<0||z>md{return -1};rows[i]=int(z);if i>0&&rows[i]<rows[i-1]{return -1} }
		if rows[0]!=0||rows[n]!=m{return -1}
		for u in 0..n { mut diag:=0;mut d:=0.0;mut offsum:=0.0;mut prev:=0
			for e in rows[u]..rows[u+1] { z:=input[ca+e];if math.trunc(z)!=z||z<0||z>=nd{return -1};cols[e]=int(z);if e>rows[u]&&cols[e]<=prev{return -1};prev=cols[e];mat[e]=input[va+e];if mat[e]<-4||mat[e]>4{return -1};if cols[e]==u{diag++;d=mat[e]}else{if group[u]==group[cols[e]]{return -1};offsum+=math.abs(mat[e])} }
			if diag!=1||d<=offsum{return -1};for e in rows[u]..rows[u+1]{v:=cols[e];mut found:=false;for f in rows[v]..rows[v+1]{if cols[f]==u{if mat[f]!=mat[e]{return -1};found=true;break}};if !found{return -1}}
		}
		for i in 0..n{x[i]=input[xa+i];rhs[i]=input[ba+i];if x[i]<-4||x[i]>4||rhs[i]<-4||rhs[i]>4{return -1}}
		if output==nil||capacity<usize(n){return -2}
		for pass in 0..2{for step in 0..colors{k:=step;if pass==1{k=colors-1-step};for p in offsets[k]..offsets[k+1]{u:=order[p];mut sum:=0.0;mut d:=0.0;for e in rows[u]..rows[u+1]{v:=cols[e];if v==u{d=mat[e]}else{sum+=x[v]*mat[e]}};if d!=0{x[u]=(rhs[u]-sum)/d}}}}
		for i in 0..n{staged[i]=x[i]};for i in 0..n{output[i]=staged[i]};return i64(n)
	}
}
