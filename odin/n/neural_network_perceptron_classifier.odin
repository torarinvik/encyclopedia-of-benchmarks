package neural_network_perceptron_classifier
import "core:c"
@(export)
neural_network_perceptron_classifier :: proc "c" (v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n<5 do return -1;f,s,bias:=v[0],v[1],v[2];if f<1||f>3||s<1||s>4||bias < -10000||bias>10000||int(n)!=3+int(f)+int(f*s) do return -1;for i:=0;i<int(f);i+=1{if v[3+i] < -10000||v[3+i]>10000 do return -1};for i:=3+int(f);i<int(n);i+=1{if v[i] < -10||v[i]>10 do return -1};if o==nil||cap<c.size_t(s) do return -2;for j:=0;j<int(s);j+=1{z:=bias;for i:=0;i<int(f);i+=1{z+=v[3+i]*v[3+int(f)+i*int(s)+j]};if z>0{o[j]=1}else{o[j]=0}};return s}
