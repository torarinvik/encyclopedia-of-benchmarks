module minimum_tickets_cost
@[export: 'minimum_tickets_cost']
pub fn minimum_tickets_cost(v &i64,n usize)i64{unsafe{if v==nil||n<4||n>369||v[0]<0||v[0]>365{return -1};d:=int(v[0]);if n!=d+4{return -1};mut travel:=[366]bool{};for i in 0..d{x:=v[i+1];if x<1||x>365||travel[int(x)]{return -1};travel[int(x)]=true};c0:=v[d+1];c1:=v[d+2];c2:=v[d+3];if c0<0||c0>1000000||c1<0||c1>1000000||c2<0||c2>1000000{return -1};mut dp:=[397]i64{};for day in 0..365{idx:=365-day;dp[idx]=dp[idx+1];if travel[idx]{dp[idx]=min(c0+dp[idx+1],min(c1+dp[idx+7],c2+dp[idx+30]))}};return dp[1]}}
