#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxIterations = 1000000;
constexpr int kIdle = 1, kWork = 2, kHandlerA = 3, kHandlerB = 4, kDeviceA = 5, kDeviceB = 6;
constexpr int kDevicePacket = 1000, kWorkPacket = 1001;
constexpr int kPacketBit = 1, kWaitBit = 2, kHoldBit = 4;
constexpr int kRun = 0, kRunPacket = 1, kWait = 2, kWaitPacket = 3;
constexpr int kHold = 4, kHoldPacket = 5, kHoldWait = 6, kHoldWaitPacket = 7;
constexpr int kBufferSize = 3, kMaxInt = 32767;
struct Packet { int link, id, kind, a1, a2[4]; };
struct Task { int link, id, priority, queue, state; std::int64_t v1, v2; };
Packet packets[9];
Task tasks[7];
int packetUsed, taskList, current, taskId, packetCount, holdCount;
std::int64_t v1, v2;

int makePacket(int link, int id, int kind) {
    const int index = ++packetUsed;
    packets[index] = Packet{link, id, kind, 0, {0, 0, 0, 0}};
    return index;
}
void makeTask(int id, int priority, int queue, int state, std::int64_t a, std::int64_t b) {
    tasks[id] = Task{taskList, id, priority, queue, state, a, b};
    taskList = id;
}
void appendPacket(int packet, int *head) {
    packets[packet].link = 0;
    if (*head == 0) { *head = packet; return; }
    int tail = *head;
    while (packets[tail].link != 0) tail = packets[tail].link;
    packets[tail].link = packet;
}
int queuePacket(int packet) {
    const int destination = packets[packet].id;
    Task &target = tasks[destination];
    ++packetCount;
    packets[packet].link = 0;
    packets[packet].id = taskId;
    if (target.queue == 0) {
        target.queue = packet;
        target.state |= kPacketBit;
        if (target.priority > tasks[taskId].priority) return destination;
    } else appendPacket(packet, &target.queue);
    return current;
}
int releaseTask(int destination) {
    Task &target = tasks[destination];
    target.state &= ~kHoldBit;
    return target.priority > tasks[taskId].priority ? destination : current;
}
int waitTask() { tasks[taskId].state |= kWaitBit; return taskId; }
int holdTask() {
    ++holdCount;
    tasks[taskId].state |= kHoldBit;
    return tasks[taskId].link;
}
int runTask(int packet) {
    if (taskId == kIdle) {
        --v2;
        if (v2 == 0) return holdTask();
        if ((v1 & 1) == 0) { v1 = (v1 >> 1) & kMaxInt; return releaseTask(kDeviceA); }
        v1 = ((v1 >> 1) & kMaxInt) ^ 0xD008;
        return releaseTask(kDeviceB);
    }
    if (taskId == kWork) {
        if (packet == 0) return waitTask();
        static constexpr char alphabet[] = "0ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        v1 = kHandlerA + kHandlerB - v1;
        packets[packet].id = static_cast<int>(v1);
        packets[packet].a1 = 0;
        for (int index = 0; index <= kBufferSize; ++index) {
            ++v2;
            if (v2 > 26) v2 = 1;
            packets[packet].a2[index] = alphabet[v2];
        }
        return queuePacket(packet);
    }
    if (taskId == kHandlerA || taskId == kHandlerB) {
        if (packet != 0) {
            if (packets[packet].kind == kWorkPacket) {
                int head = static_cast<int>(v1); appendPacket(packet, &head); v1 = head;
            } else {
                int head = static_cast<int>(v2); appendPacket(packet, &head); v2 = head;
            }
        }
        if (v1 != 0) {
            const int workPacket = static_cast<int>(v1);
            const int count = packets[workPacket].a1;
            if (count > kBufferSize) {
                v1 = packets[workPacket].link;
                return queuePacket(workPacket);
            }
            if (v2 != 0) {
                const int devicePacket = static_cast<int>(v2);
                v2 = packets[devicePacket].link;
                packets[devicePacket].a1 = packets[workPacket].a2[count];
                packets[workPacket].a1 = count + 1;
                return queuePacket(devicePacket);
            }
        }
        return waitTask();
    }
    if (packet == 0) {
        if (v1 == 0) return waitTask();
        packet = static_cast<int>(v1); v1 = 0;
        return queuePacket(packet);
    }
    v1 = packet;
    return holdTask();
}
int schedule() {
    while (current != 0) {
        int packet = 0;
        Task &task = tasks[current];
        if (task.state == kWaitPacket) {
            packet = task.queue;
            task.queue = packets[packet].link;
            task.state = task.queue == 0 ? kRun : kRunPacket;
        }
        if (task.state == kRun || task.state == kRunPacket) {
            taskId = task.id; v1 = task.v1; v2 = task.v2;
            current = runTask(packet);
            task.v1 = v1; task.v2 = v2;
        } else if (task.state == kWait || task.state == kHold || task.state == kHoldPacket ||
                   task.state == kHoldWait || task.state == kHoldWaitPacket) current = task.link;
        else return -1;
    }
    return 0;
}
}

extern "C" std::int64_t richards_benchmark(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > kMaxIterations) return -1;
    for (auto &packet : packets) packet = Packet{};
    for (auto &task : tasks) task = Task{};
    packetUsed = taskList = current = taskId = packetCount = holdCount = 0;
    v1 = v2 = 0;
    int work = makePacket(0, 0, kWorkPacket);
    work = makePacket(work, 0, kWorkPacket);
    makeTask(kIdle, 0, 0, kRun, 1, input[0]);
    makeTask(kWork, 1000, work, kWaitPacket, kHandlerA, 0);
    int handlerA = makePacket(0, kDeviceA, kDevicePacket);
    handlerA = makePacket(handlerA, kDeviceA, kDevicePacket);
    handlerA = makePacket(handlerA, kDeviceA, kDevicePacket);
    makeTask(kHandlerA, 2000, handlerA, kWaitPacket, 0, 0);
    int handlerB = makePacket(0, kDeviceB, kDevicePacket);
    handlerB = makePacket(handlerB, kDeviceB, kDevicePacket);
    handlerB = makePacket(handlerB, kDeviceB, kDevicePacket);
    makeTask(kHandlerB, 3000, handlerB, kWaitPacket, 0, 0);
    makeTask(kDeviceA, 4000, 0, kWait, 0, 0);
    makeTask(kDeviceB, 5000, 0, kWait, 0, 0);
    current = taskList;
    if (schedule() != 0) return -1;
    return static_cast<std::int64_t>(packetCount) * INT64_C(2147483648) + holdCount;
}
