#include "keyboard_hook.h"

#include <hidusage.h>

namespace keyboard_hook {

namespace {

HHOOK g_hook = nullptr;
HHOOK g_wh_keyboard_ll = nullptr;

// Blocked keys during exam
constexpr DWORD kBlockedModKeys[] = {
  VK_LWIN, VK_RWIN,          // Windows key
  VK_SNAPSHOT,               // Print Screen
  VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6,
  VK_F7, VK_F8, VK_F9, VK_F10, VK_F11, VK_F12,
  VK_ESCAPE,                 // Esc (blocks alt+esc too)
};

bool IsBlockedKey(DWORD vk) {
  for (auto key : kBlockedModKeys) {
    if (vk == key) return true;
  }
  return false;
}

LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode >= 0) {
    KBDLLHOOKSTRUCT* p = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);
    bool isAltDown = (p->flags & LLKHF_ALTDOWN) != 0;
    bool isCtrlDown = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;

    // Block Alt+Tab, Alt+Esc, Alt+F4
    if (isAltDown) {
      if (p->vkCode == VK_TAB || p->vkCode == VK_ESCAPE || p->vkCode == VK_F4) {
        return 1;
      }
    }

    // Block Ctrl+Esc (opens Start menu)
    if (isCtrlDown && p->vkCode == VK_ESCAPE) {
      return 1;
    }

    // Block Ctrl+Shift+Esc (Task Manager)
    if (isCtrlDown && (GetAsyncKeyState(VK_SHIFT) & 0x8000) && p->vkCode == VK_ESCAPE) {
      return 1;
    }

    // Block Alt+Space (window menu), Alt+F4 caught above
    if (isAltDown && p->vkCode == VK_SPACE) {
      return 1;
    }

    // Block individual blocked keys
    if (IsBlockedKey(p->vkCode)) {
      return 1;
    }
  }

  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

}  // namespace

bool Install() {
  if (g_hook != nullptr) return true;  // already installed

  HMODULE hMod = GetModuleHandle(nullptr);
  g_wh_keyboard_ll = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, hMod, 0);

  if (g_wh_keyboard_ll == nullptr) {
    return false;
  }

  g_hook = g_wh_keyboard_ll;
  return true;
}

void Remove() {
  if (g_wh_keyboard_ll != nullptr) {
    UnhookWindowsHookEx(g_wh_keyboard_ll);
    g_wh_keyboard_ll = nullptr;
  }
  g_hook = nullptr;
}

bool IsActive() {
  return g_wh_keyboard_ll != nullptr;
}

}  // namespace keyboard_hook