#include "hdd.h"
#include "../sketchybar.h"
#include <sys/statvfs.h>
#include <unistd.h>

// Optional external drive — set EXTERNAL_DRIVE in the environment to a
// mount path (e.g. "/Volumes/ExternalDrive") to include it in the
// total. If unset, missing, or unmounted, only root disk is reported.

int main (int argc, char** argv) {
    float update_freq;
    if (argc < 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
        printf("Usage: %s \"<event-name>\" \"<event_freq>\"\n", argv[0]);
        exit(1);
    }

    alarm(0);
    struct disk_info root_disk;
    disk_init(&root_disk);

    const char* external_path = getenv("EXTERNAL_DRIVE");
    int external_active = (external_path != NULL
                           && external_path[0] != '\0'
                           && access(external_path, F_OK) == 0);

    struct disk_info external_disk;
    if (external_active) disk_init(&external_disk);

    // Setup the event in sketchybar
    char event_message[512];
    snprintf(event_message, 512, "--add event '%s'", argv[1]);
    sketchybar(event_message);

    char trigger_message[1024];
    for (;;) {
        disk_update(&root_disk, "/");
        double total_free_tb = root_disk.free_space / 1024.0;

        if (external_active && access(external_path, F_OK) == 0) {
            disk_update(&external_disk, external_path);
            total_free_tb += external_disk.free_space / 1024.0;
        }

        snprintf(trigger_message, 1024,
                 "--trigger '%s' available='%.1fT'",
                 argv[1],
                 total_free_tb);
        sketchybar(trigger_message);

        usleep(update_freq * 1000000);
    }
    return 0;
}
