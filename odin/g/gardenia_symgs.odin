// Clean-room bounded GARDENIA SymGS profile.
package gardenia_symgs
import "core:c"
import "core:math"

@(export)
gardenia_symgs :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length<3||length>173 do return -1
	for q:=0;q<int(length);q+=1 { if !math.is_finite(input[q]) do return -1 }
	nd,md,cd:=input[0],input[1],input[2]
	if math.trunc(nd)!=nd||math.trunc(md)!=md||math.trunc(cd)!=cd||nd<1||nd>8||md<1||md>64||cd<1||cd>nd do return -1
	n,m,colors:=int(nd),int(md),int(cd);if int(length)!=5+4*n+colors+2*m do return -1
	oa,fa,ra,ca,va,xa,ba:=3,3+n,3+n+colors+1,3+n+colors+1+n+1,3+n+colors+1+n+1+m,3+n+colors+1+n+1+2*m,3+n+colors+1+n+1+2*m+n
	var order:[8]int;var offsets:[9]int;var rows:[9]int;var cols:[64]int;var group:[8]int
	var mat:[64]f64;var x:[8]f64;var rhs:[8]f64;var staged:[8]f64;var seen:[8]bool
	for i:=0;i<n;i+=1 { z:=input[oa+i];if math.trunc(z)!=z||z<0||z>=nd||seen[int(z)] do return -1;order[i]=int(z);seen[order[i]]=true }
	for k:=0;k<=colors;k+=1 { z:=input[fa+k];if math.trunc(z)!=z||z<0||z>nd do return -1;offsets[k]=int(z) }
	if offsets[0]!=0||offsets[colors]!=n do return -1
	for k:=0;k<colors;k+=1 { if offsets[k]>=offsets[k+1] do return -1;for p:=offsets[k];p<offsets[k+1];p+=1 { group[order[p]]=k } }
	for i:=0;i<=n;i+=1 { z:=input[ra+i];if math.trunc(z)!=z||z<0||z>md do return -1;rows[i]=int(z);if i>0&&rows[i]<rows[i-1] do return -1 }
	if rows[0]!=0||rows[n]!=m do return -1
	for u:=0;u<n;u+=1 { diag:=0;d,offsum:=0.0,0.0;prev:=0
		for e:=rows[u];e<rows[u+1];e+=1 { z:=input[ca+e];if math.trunc(z)!=z||z<0||z>=nd do return -1;cols[e]=int(z);if e>rows[u]&&cols[e]<=prev do return -1;prev=cols[e];mat[e]=input[va+e];if mat[e]<-4||mat[e]>4 do return -1
			if cols[e]==u { diag+=1;d=mat[e] } else { if group[u]==group[cols[e]] do return -1;offsum+=math.abs(mat[e]) }
		}
		if diag!=1||d<=offsum do return -1
		for e:=rows[u];e<rows[u+1];e+=1 { v:=cols[e];found:=false;for f:=rows[v];f<rows[v+1];f+=1 { if cols[f]==u { if mat[f]!=mat[e] do return -1;found=true;break } };if !found do return -1 }
	}
	for i:=0;i<n;i+=1 { x[i]=input[xa+i];rhs[i]=input[ba+i];if x[i]<-4||x[i]>4||rhs[i]<-4||rhs[i]>4 do return -1 }
	if output==nil||capacity<c.size_t(n) do return -2
	for pass:=0;pass<2;pass+=1 { for step:=0;step<colors;step+=1 { k:=step;if pass==1 { k=colors-1-step };for p:=offsets[k];p<offsets[k+1];p+=1 { u:=order[p];sum,d:=0.0,0.0;for e:=rows[u];e<rows[u+1];e+=1 { v:=cols[e];if v==u { d=mat[e] } else { sum+=x[v]*mat[e] } };if d!=0 { x[u]=(rhs[u]-sum)/d } } } }
	for i:=0;i<n;i+=1 { staged[i]=x[i] };for i:=0;i<n;i+=1 { output[i]=staged[i] };return i64(n)
}
