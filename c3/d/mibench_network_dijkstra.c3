module mibench_network_dijkstra;
const int MAX_NODES=6, MAX_QUEUE_ITEMS=1024;
const long NONE=9999;
struct QueueItem { int node; long distance; int previous; }

fn long mibench_network_dijkstra(long* input, usz length) @export("mibench_network_dijkstra") {
    if(input==null||length<3)return -1;
    long node_value=input[0];
    if(node_value<1||node_value>MAX_NODES)return -1;
    int nodes=(int)node_value;
    if(length!=(usz)(2+nodes*nodes))return -1;
    long source_value=input[1];
    if(source_value<0||source_value>=node_value)return -1;
    for(int i=0;i<nodes*nodes;i++){
        long cost=input[2+i];
        if(cost!=NONE&&(cost<0||cost>31))return -1;
    }
    long[MAX_NODES] distance;
    bool[MAX_NODES] reachable;
    QueueItem[MAX_QUEUE_ITEMS] queue;
    for(int i=0;i<nodes;i++){distance[i]=NONE;reachable[i]=false;}
    int source=(int)source_value;
    distance[source]=0;reachable[source]=true;
    usz head=0,tail=0;
    queue[tail]=QueueItem{source,0,(int)NONE};tail++;
    while(head<tail){
        QueueItem item=queue[head];head++;
        for(int destination=0;destination<nodes;destination++){
            long cost=input[2+item.node*nodes+destination];
            if(cost==NONE)continue;
            long candidate=item.distance+cost;
            if(!reachable[destination]||distance[destination]>candidate){
                distance[destination]=candidate;reachable[destination]=true;
                if(tail>=MAX_QUEUE_ITEMS)return -2;
                queue[tail]=QueueItem{destination,candidate,item.node};tail++;
            }
        }
    }
    long checksum=0;ulong mask=0;
    for(int node=0;node<nodes;node++)if(reachable[node]){
        checksum+=(long)(node+1)*distance[node];mask|=(ulong)1<<node;
    }
    return checksum+(long)mask;
}
