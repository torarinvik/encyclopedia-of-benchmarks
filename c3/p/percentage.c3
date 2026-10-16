module percentage;
fn long percentage(long* v,usz n) @export("percentage") {
 if(v==null||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4)return -1;
 long scale=1;for(long i=0;i<v[2];i+=1)scale*=10;long product=v[0]*v[1]*scale;if(product<100)return -1;return product/100;
}
