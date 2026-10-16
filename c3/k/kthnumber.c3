module kthnumber;
fn long part(long*a,long l,long h){long p=a[h],i=l;for(long j=l;j<h;j++)if(a[j]<p){long t=a[i];a[i]=a[j];a[j]=t;i++;}long t=a[i];a[i]=a[h];a[h]=t;return i;}
fn long kthnumber(long*v,usz n) @export("kthnumber"){if(n<4||n>19)return -1;long count=v[0],mode=v[1],k=v[2];if(count<1||count>16||n!=count+3||(mode!=1&&mode!=2)||k<1||k>count)return -1;long a[16];for(long i=0;i<count;i++){a[i]=v[i+3];if(a[i]<-10000||a[i]>10000)return -1;}long target=mode==1?k-1:count-k,l=0,h=count-1;while(l<=h){long q=part(a,l,h);if(q==target)return a[q];if(q<target)l=q+1;else h=q-1;}return -1;}
