package equal_loudness_filter
import "core:c"
import "core:runtime"
A :: [11]i64{1073741824, -3875279605, 7242592440, -9849938776, 11019995787, -10310050823, 8022431451, -5130046574, 2558322377, -874363774, 153873500}
B :: [11]i64{60930872, -44894685, -5549718, -9621322, -7681698, 30506759, -32060412, 22380311, -4826655, 8028337, -4488672}
HA :: [11]i64{1089966811, -2146993250, 1057516837, 0, 0, 0, 0, 0, 0, 0, 0}
HB :: [11]i64{1073619225, -2147238449, 1073619225, 0, 0, 0, 0, 0, 0, 0, 0}
step :: proc(sample:i64,a,b:[11]i64,order:int,x,y:[^]i64)->i64 {
    acc:=b[0]*sample
    for i:=1;i<=order;i+=1 {acc+=b[i]*x[i-1]-a[i]*y[i-1]}
    out:=acc/a[0]
    for i:=order-1;i>0;i-=1{x[i]=x[i-1];y[i]=y[i-1]}
    if order>0{x[0]=sample;y[0]=out}
    return out
}
@(export)
equal_loudness_filter :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
    context = runtime.default_context()
    if v==nil||n<1||n>33{return -1}
    count:=v[0];if count<0||count>32||n!=c.size_t(count+1){return -1}
    x:[10]i64;y:[10]i64;hx:[2]i64;hy:[2]i64;output:=i64(0)
    for i:=i64(0);i<count;i+=1{sample:=v[i+1];if sample < -1000000||sample>1000000{return -1};mid:=step(sample,A,B,10,&x[0],&y[0]);output=step(mid,HA,HB,2,&hx[0],&hy[0])}
    return output
}
