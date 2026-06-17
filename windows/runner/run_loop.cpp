#include "run_loop.h"

#include <flutter/flutter_view_controller.h>
#include <windows.h>

RunLoop::RunLoop() {}

RunLoop::~RunLoop() {}

void RunLoop::Run() {
  bool keep_running = true;
  TimePoint next_flutter_event_time = TimePoint::clock::now();
  while (keep_running) {
    // Wait until either a Windows message is available or the next Flutter
    // event is due.
    std::chrono::nanoseconds wait_duration =
        std::max(std::chrono::nanoseconds(0),
                 next_flutter_event_time - TimePoint::clock::now());
    ::MsgWaitForMultipleObjects(
        0, nullptr, FALSE,
        static_cast<DWORD>(
            std::chrono::duration_cast<std::chrono::milliseconds>(wait_duration)
                .count()),
        QS_ALLINPUT);
    bool processed_events = false;
    MSG message;
    while (::PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      processed_events = true;
      if (message.message == WM_QUIT) {
        keep_running = false;
        break;
      }
      ::TranslateMessage(&message);
      ::DispatchMessage(&message);
    }

    // Handle any events from Flutter, and retrieve the arrival time of the
    // next event.
    next_flutter_event_time = ProcessFlutterMessages();
  }
}

void RunLoop::RegisterFlutterInstance(
    flutter::FlutterEngine* flutter_instance) {
  flutter_instances_.insert(flutter_instance);
}

void RunLoop::UnregisterFlutterInstance(
    flutter::FlutterEngine* flutter_instance) {
  flutter_instances_.erase(flutter_instance);
}

RunLoop::TimePoint RunLoop::ProcessFlutterMessages() {
  TimePoint next_event_time = TimePoint::max();
  for (auto* engine : flutter_instances_) {
    TimePoint engine_next_event_time =
        engine->ProcessExternalEvents();
    if (engine_next_event_time < next_event_time) {
      next_event_time = engine_next_event_time;
    }
  }
  return next_event_time;
}
