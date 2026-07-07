<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(private NotificationService $service) {}

    public function index(Request $request)
    {
        return response()->json($this->service->getUnread($request->user()->id));
    }

    public function markRead(Request $request, Notification $notification)
    {
        if ($notification->user_id !== $request->user()->id) abort(403);
        $notification->markRead();
        return response()->json(['message' => 'Ditandai terbaca.']);
    }

    public function markAllRead(Request $request)
    {
        $this->service->markAllRead($request->user()->id);
        return response()->json(['message' => 'Semua notifikasi ditandai terbaca.']);
    }
}
