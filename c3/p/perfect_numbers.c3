module perfect_numbers;
fn long perfect_numbers(long* v,usz n) @export("perfect_numbers"){if(v==null||n!=1||v[0]<0||v[0]>1000000000)return -1;long x=v[0];if(x<=1)return 0;long sum=1;for(long d=2;d<=x/d;d++){if(x%d==0){sum+=d;long q=x/d;if(d!=q)sum+=q;}}return sum==x;}
