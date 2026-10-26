package tsvc_s441_s443_d_sign_branch_updates
import "core:c"
import "core:math"
@(export) tsvc_s441_s443_d_sign_branch_updates :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{
 if x==nil||l<7||l>259 do return -1
 mode_raw:=x[0];rn:=x[1];rp:=x[2];if mode_raw!=mode_raw||math.trunc(mode_raw)!=mode_raw||(mode_raw!=0&&mode_raw!=1)||rn!=rn||math.trunc(rn)!=rn||rn<1||rn>64||rp!=rp||math.trunc(rp)!=rp||rp<1||rp>8 do return -1
 mode:=int(mode_raw);n:=int(rn);passes:=int(rp);if l!=c.size_t(3+4*n)do return -1
 for i:=3;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||cap<c.size_t(n)do return -2
 var a:[64]f64;bb:=3+n;cc:=3+2*n;dd:=3+3*n;for i:=0;i<n;i+=1{a[i]=x[3+i]}
 for _:=0;_<passes;_+=1{for i:=0;i<n;i+=1{if mode==0{if x[dd+i]<0{a[i]+=x[bb+i]*x[cc+i]}else if x[dd+i]==0{a[i]+=x[bb+i]*x[bb+i]}else{a[i]+=x[cc+i]*x[cc+i]}}else if x[dd+i]<=0{a[i]+=x[bb+i]*x[cc+i]}else{a[i]+=x[bb+i]*x[bb+i]}}}
 for i:=0;i<n;i+=1{y[i]=a[i]};return i64(n)
}
