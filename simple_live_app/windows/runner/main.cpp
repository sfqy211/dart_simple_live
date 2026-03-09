#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <iostream>
#include <string>
#include <streambuf>

#include "flutter_window.h"
#include "utils.h"
#include "window_manager_plus/window_manager_plus_plugin.h"

class AccessibilityLogFilter : public std::streambuf {
 public:
  AccessibilityLogFilter(std::ostream& stream)
      : stream_(stream), original_buffer_(stream.rdbuf()) {
    stream_.rdbuf(this);
  }

  ~AccessibilityLogFilter() {
    if (!current_line_.empty()) {
      process_line();
    }
    stream_.rdbuf(original_buffer_);
  }

 protected:
  int overflow(int c) override {
    if (c == EOF) {
      return !EOF;
    }
    char ch = static_cast<char>(c);
    current_line_ += ch;
    if (ch == '\n') {
      process_line();
    }
    return c;
  }

  int sync() override { return original_buffer_->pubsync(); }

 private:
  void process_line() {
    if (current_line_.find("Failed to update ui::AXTree") ==
            std::string::npos &&
        current_line_.find("Problem getting monitor brightness") ==
            std::string::npos &&
        current_line_.find("Problem setting monitor brightness") ==
            std::string::npos) {
      original_buffer_->sputn(current_line_.c_str(), current_line_.size());
    }
    current_line_.clear();
  }

  std::ostream& stream_;
  std::streambuf* original_buffer_;
  std::string current_line_;
};

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  AccessibilityLogFilter log_filter(std::cerr);
  AccessibilityLogFilter log_filter_out(std::cout);

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"simple_live_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  WindowManagerPlusPluginSetWindowCreatedCallback(
      [](std::vector<std::string> command_line_arguments) {
        flutter::DartProject project(L"data");
        project.set_dart_entrypoint_arguments(
            std::move(command_line_arguments));

        auto window = std::make_shared<FlutterWindow>(project);
        Win32Window::Point origin(10, 10);
        Win32Window::Size size(1280, 720);
        if (!window->Create(L"simple_live_app", origin, size)) {
          std::cerr << "Failed to create a new window" << std::endl;
        }
        window->SetQuitOnClose(false);
        return std::move(window);
      });

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
