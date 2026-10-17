package shortest_word_distance
import "core:c"
MAX_WORDS::32
MAX_INPUT::307
eq::proc(v:[^]i64,s,n,t,m:int)->bool{if n!=m do return false;for i:=0;i<n;i+=1{if v[s+i]!=v[t+i] do return false};return true}
@(export)
shortest_word_distance::proc "c"(v:[^]i64,length:c.size_t)->i64{if v==nil||length<1||length>308 do return -1;if v[0]<2||v[0]>32 do return -1;n:=int(v[0]);starts:[32]int;sizes:[32]int;p:=1;for i:=0;i<n;i+=1{if p>=int(length) do return -1;z:=v[p];p+=1;if z<1||z>8||p+int(z)>int(length) do return -1;starts[i]=p;sizes[i]=int(z);for j:=0;j<int(z);j+=1{if !((v[p+j]>=65&&v[p+j]<=90)||(v[p+j]>=97&&v[p+j]<=122)) do return -1};p+=int(z)};ts:[2]int;tn:[2]int;for t:=0;t<2;t+=1{if p>=int(length) do return -1;z:=v[p];p+=1;if z<1||z>8||p+int(z)>int(length) do return -1;ts[t]=p;tn[t]=int(z);for j:=0;j<int(z);j+=1{if !((v[p+j]>=65&&v[p+j]<=90)||(v[p+j]>=97&&v[p+j]<=122)) do return -1};p+=int(z)};if p!=int(length)||eq(v,ts[0],tn[0],ts[1],tn[1]) do return -1;h0:=false;h1:=false;best:=n;for i:=0;i<n;i+=1{a:=eq(v,starts[i],sizes[i],ts[0],tn[0]);b:=eq(v,starts[i],sizes[i],ts[1],tn[1]);h0=h0||a;h1=h1||b;for j:=0;j<n;j+=1{c0:=eq(v,starts[j],sizes[j],ts[0],tn[0]);d:=eq(v,starts[j],sizes[j],ts[1],tn[1]);if(a&&d)||(b&&c0){delta:=i-j;if delta<0 do delta=-delta;if delta<best do best=delta}}};if h0&&h1{return i64(best)};return -1}
