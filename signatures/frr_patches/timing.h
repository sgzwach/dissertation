#ifndef TIMING_H
#define TIMING_H

#include <time.h>
#include <stdlib.h>
#include <stdio.h>

void writeTime(const char *, char *);

void writeTime(const char *msg, char *msg2) {
    FILE *ofp = fopen("/cap/log.txt", "a+");

    // get time
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);

    // write time & message
    fprintf(ofp, "%s,%s,%ld,%ld\n", msg, msg2, ts.tv_sec, ts.tv_nsec);
    fclose(ofp);
}
#endif