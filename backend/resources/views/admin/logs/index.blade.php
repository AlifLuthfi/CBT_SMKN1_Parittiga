@extends('layouts.app')
@section('title', 'Log Aktivitas')
@section('page-title', 'Log Aktivitas')
@section('content')
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>User</th><th>Aksi</th><th>Deskripsi</th><th>Waktu</th></tr></thead>
      <tbody>
        @forelse($logs as $log)
        <tr>
          <td class="td-main">{{ $log->user?->name ?? 'System' }}</td>
          <td><span class="badge b-navy">{{ $log->action }}</span></td>
          <td class="td-sm">{{ $log->description }}</td>
          <td class="td-sm">{{ $log->created_at->format('d/m/Y H:i') }}</td>
        </tr>
        @empty
        <tr><td colspan="4" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada aktivitas</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $logs->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endSection
