<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        if ($user->status !== 'active') {
            return response()->json(['message' => 'Akun Anda tidak aktif. Hubungi admin.'], 403);
        }

        $deviceName = $request->device_name ?? ($request->header('User-Agent') ?? 'unknown');
        $token      = $user->createToken($deviceName)->plainTextToken;

        $user->load('enrolledClasses');
        $user->update(['last_login_at' => now()]);

        ActivityLog::create([
            'user_id'    => $user->id,
            'action'     => 'login',
            'description'=> "{$user->name} login ({$user->role})",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'token' => $token,
            'user'  => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'role'  => $user->role,
                'nip'   => $user->nip,
                'nis'   => $user->nis,
                'avatar'=> $user->avatar,
            ],
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user()->load('enrolledClasses');
        return response()->json(['user' => $user]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Berhasil logout.']);
    }

    public function logoutAll(Request $request)
    {
        $request->user()->tokens()->delete();
        return response()->json(['message' => 'Logout dari semua perangkat.']);
    }
}
