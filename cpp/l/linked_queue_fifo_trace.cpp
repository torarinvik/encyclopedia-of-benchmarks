/* Run a linked FIFO operation trace and drain the remaining values. */
#include <cstddef>
#include <cstdint>
namespace {void put(std::uint8_t*out,std::size_t i,std::int32_t value){auto bits=static_cast<std::uint32_t>(value);for(std::size_t b=0;b<4;++b)out[i*4+b]=static_cast<std::uint8_t>(bits>>(8*b));}}
extern "C" std::int64_t linked_queue_fifo_trace(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
 if(!in||len<1)return -1;auto n64=in[0];if(n64<0||n64>127||len!=static_cast<std::size_t>(1+2*n64))return -1;auto n=static_cast<std::size_t>(n64);std::int64_t values[127]{},next[127],result[127]{};for(auto &x:next)x=-1;std::int64_t head=-1,rear=-1;std::size_t nodes=0,count=0;bool closed=false;
 for(std::size_t i=0;i<n;++i){auto op=in[1+2*i],v=in[2+2*i];if(op==0){if(closed||v<INT32_MIN||v>INT32_MAX||nodes>=127)return -1;auto node=static_cast<std::int64_t>(nodes++);values[node]=v;next[node]=-1;if(head<0)head=node;else next[rear]=node;rear=node;}else if(op==1){if(v!=0||head<0)return -1;result[count++]=values[head];head=next[head];if(head<0){rear=-1;closed=true;}}else return -1;}
 while(head>=0){result[count++]=values[head];head=next[head];}const auto bytes=count*4;if(bytes&&(!out||cap<bytes))return -2;for(std::size_t i=0;i<count;++i)put(out,i,static_cast<std::int32_t>(result[i]));return static_cast<std::int64_t>(bytes);
}
