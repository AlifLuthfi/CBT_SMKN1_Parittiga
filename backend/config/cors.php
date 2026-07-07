<?php
return [
    'paths'           => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    // Untuk production, ganti dengan domain spesifik:
    // 'allowed_origins' => ['https://examcore.sekolah.sch.id'],
    'allowed_headers' => ['*'],
    'max_age'         => 0,
    'supports_credentials' => false,
];
