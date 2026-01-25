if(TARGET_TIZEN)
  list(APPEND SOURCES TestWinSystemWaylandTizen.cpp)
endif()

if(SOURCES)
  core_add_test_library(windowing_wayland_test)
endif()
