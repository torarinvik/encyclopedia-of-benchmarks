package rodinia_streamcluster_pgain
import "core:c"
put64 :: proc(outp: [^]u8, i: int, value: i64) { raw:=u64(value); for b in 0..<8 { outp[i*8+b]=u8(raw>>(b*8)) } }
@(export)
rodinia_streamcluster_pgain :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if values==nil||length<5||length>53{return -1};pn:=values[0];dim:=values[1];candidate:=values[2];z:=values[3];mask:=values[4];if pn<2||pn>8||dim<1||dim>3||length!=c.size_t(5+pn*(3+dim))||candidate<0||candidate>=pn||z<1||z>64||mask<=0||u64(mask)>=(u64(1)<<u32(pn))||(mask&(i64(1)<<u32(candidate)))!=0{return -1};p:=int(pn);d:=int(dim);x:=int(candidate);q:=5;ass:[8]int{};weights:[8]i64{};costs:[8]i64{};points:[8][3]i64{};
 for i in 0..<p{if values[q]<0||values[q]>=pn{return -1};ass[i]=int(values[q]);q+=1;if mask&(i64(1)<<u32(ass[i]))==0{return -1}};for i in 0..<p{if values[q]<1||values[q]>4{return -1};weights[i]=values[q];q+=1};for i in 0..<p{costs[i]=values[q];q+=1};for i in 0..<p{for k in 0..<d{if values[q]<-8||values[q]>8{return -1};points[i][k]=values[q];q+=1}}
 for i in 0..<p{ds:i64=0;for k in 0..<d{t:=points[i][k]-points[ass[i]][k];ds+=t*t};if costs[i]!=weights[i]*ds||(mask&(i64(1)<<u32(i))!=0&&(ass[i]!=i||costs[i]!=0)){return -1}};sw:[8]bool{};cl:[8]bool{};low:[8]i64{};opening:=z
 for i in 0..<p{ds:i64=0;for k in 0..<d{t:=points[i][k]-points[x][k];ds+=t*t};xc:=weights[i]*ds;if xc<costs[i]{sw[i]=true;opening+=xc-costs[i]}else{low[ass[i]]+=costs[i]-xc}};for j in 0..<p{if mask&(i64(1)<<u32(j))!=0{lo:=z+low[j];if lo>0{cl[j]=true;opening-=lo}}};opened:=opening<0;om:=mask;oa:=ass;oc:=costs
 if opened{for i in 0..<p{if sw[i]||cl[ass[i]]{ds:i64=0;for k in 0..<d{t:=points[i][k]-points[x][k];ds+=t*t};oa[i]=x;oc[i]=weights[i]*ds}};for j in 0..<p{if cl[j]{om&=~(i64(1)<<u32(j))}};om|=i64(1)<<u32(x)};count:i64=0;obj:i64=0;for j in 0..<p{if om&(i64(1)<<u32(j))!=0{count++}};obj=count*z;for i in 0..<p{obj+=oc[i]};if output==nil||capacity<c.size_t(8*(5+2*p)){return -2};r:[21]i64{};r[0]=0;if opened{r[0]=1};if opened{r[1]=-opening};r[2]=count;r[3]=om;r[4]=obj;for i in 0..<p{r[5+i]=i64(oa[i]);r[5+p+i]=oc[i]};for i in 0..<5+2*p{put64(output,i,r[i])};return i64(5+2*p)
}
