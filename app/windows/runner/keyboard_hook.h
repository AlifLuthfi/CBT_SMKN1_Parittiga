#ifndef RUNNER_KEYBOARD_HOOK_H_
#define RUNNER_KEYBOARD_HOOK_H_

#include <windows.h>

namespace keyboard_hook {

// Install low-level keyboard hook. Returns true on success.
bool Install();

// Remove the hook.
void Remove();

// Check if hook is active.
bool IsActive();

}  // namespace keyboard_hook

#endif  // RUNNER_KEYBOARD_HOOK_H_