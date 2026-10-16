package kronecker_product
import "core:c"
@(export) kronecker_product :: proc "c"(v:[^]i64,n:c.size_t)->i64{if n!=6{return -1};for i: c.size_t=0;i<6;i+=1{if v[i]<-10||v[i]>10{return -1}};x:=[8]i64{v[0]*v[4],v[0]*v[5],v[1]*v[4],v[1]*v[5],v[2]*v[4],v[2]*v[5],v[3]*v[4],v[3]*v[5]};r:i64=0;for z in x{r=r*201+z+100};return r}
