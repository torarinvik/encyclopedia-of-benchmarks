fn factorial(n:i64)i64{var x:i64=1;var i:i64=1;while(i<=n):(i+=1){x*=i;}return x;}
export fn permutation_calculation(v:[*c]const i64,n:usize)i64{if(v==null||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0])return -1;return @divTrunc(factorial(v[0]),factorial(v[0]-v[1]));}
