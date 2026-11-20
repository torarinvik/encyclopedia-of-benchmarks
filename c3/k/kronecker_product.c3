module kronecker_product;
fn long kronecker_product(long*v,usz n) @export("kronecker_product"){if(v==null||n!=6)return -1;for(usz i=0;i<6;i++)if(v[i]<-10||v[i]>10)return -1;long[8] x={v[0]*v[4],v[0]*v[5],v[1]*v[4],v[1]*v[5],v[2]*v[4],v[2]*v[5],v[3]*v[4],v[3]*v[5]};long r=0;for(usz i=0;i<8;i++)r=r*201+x[i]+100;return r;}
