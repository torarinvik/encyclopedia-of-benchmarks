#include <cstddef>
#include <cstdint>
#define MAX_INPUT 2114
#define MAX_OUTPUT 3040
extern "C" std::int64_t join(const std::int64_t *v,std::size_t n,std::uint8_t *out,std::size_t cap){
 if(!v||n<2||n>2115)return -1;std::int64_t sl=v[0],count=v[1];if(sl<0||sl>32||count<0||count>32)return -1;std::size_t cursor=2;if((std::size_t)sl>n-cursor)return -1;std::uint8_t sep[32],result[MAX_OUTPUT];for(std::size_t i=0;i<(std::size_t)sl;i++){std::int64_t x=v[cursor++];if(x<0||x>127)return -1;sep[i]=(std::uint8_t)x;}std::size_t written=0;
 for(std::size_t item=0;item<(std::size_t)count;item++){if(cursor>=n)return -1;std::int64_t len=v[cursor++];if(len<0||len>64||(std::size_t)len>n-cursor)return -1;if(item>0)for(std::size_t j=0;j<(std::size_t)sl;j++)result[written++]=sep[j];for(std::size_t j=0;j<(std::size_t)len;j++){std::int64_t x=v[cursor++];if(x<0||x>127)return -1;result[written++]=(std::uint8_t)x;}}if(cursor!=n)return -1;if(!out||cap<written)return -2;for(std::size_t i=0;i<written;i++)out[i]=result[i];return (std::int64_t)written;
}
