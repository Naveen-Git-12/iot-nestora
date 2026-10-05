#include "health_engine.h"

// Prototype reference ranges (NOT WHO diagnostic thresholds,
// NOT pregnancy-specific). Wellness context only.
#define REF_HR_REST_HIGH 100
#define REF_HR_ACTIVE_HIGH 115

void HealthEngine::contextMessage(int hr, const char *activity, bool contact,
                                  char *out, size_t cap) {
  if (!contact || hr < 0) {
    snprintf(out, cap, "Place finger on sensor for heart-rate context.");
    return;
  }
  bool moving = (strcmp(activity, "WALKING") == 0) ||
                (strcmp(activity, "ACTIVE") == 0);
  if (hr > REF_HR_ACTIVE_HIGH && moving) {
    snprintf(out, cap,
             "HR %d during %s: activity-related elevation. "
             "Different from your usual pattern? Rest and re-check.",
             hr, activity);
  } else if (hr > REF_HR_REST_HIGH && !moving) {
    snprintf(out, cap,
             "HR %d while %s: elevated compared with resting state. "
             "Rest and re-check; contact clinician if persistent.",
             hr, activity);
  } else {
    snprintf(out, cap, "HR %d (%s): steady within prototype range.", hr,
             activity);
  }
}
