<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return 'Soft BD Kubernetes Deployment Test';
});

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
    ], 200);
});