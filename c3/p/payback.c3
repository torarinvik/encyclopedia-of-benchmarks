module payback;
fn long payback(long* v,usz n) @export("payback") {
 if(v==null||n<1||n>129||v[0]<0||v[0]>128||n!=(usz)(v[0]+1))return -2;
 long total=0;for(usz i=1;i<n;i+=1){if(v[i]<-1000000||v[i]>1000000)return -2;total+=v[i];if(total>=0)return (i-1).long();}return -1;
}
