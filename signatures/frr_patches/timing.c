#include <time.h>
#include <stdlib.h>
#include <stdio.h>

void writeTime(const char *msg) {
    FILE *ofp = fopen("/cap/log.txt", "a+");

    // get time
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);

    // write time & message
    fprintf(ofp, "%s,%ld,%ld\n", msg, ts.tv_sec, ts.tv_nsec);
    fclose(ofp);
}



// int main() {
//     writeTime("Test message");
//     return 0;
// }