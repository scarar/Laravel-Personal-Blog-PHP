<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\PostController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;

// Basic routes
Route::get('/', [PostController::class, 'index']);
Route::get('/home', [HomeController::class, 'index'])->name('home');

// Authentication Routes
Auth::routes();

// Blog routes
Route::prefix('posts')->group(function () {
    // Public routes
    Route::get('/', [PostController::class, 'index'])->name('posts.index');
    Route::get('/{post}', [PostController::class, 'show'])->name('posts.show');

    // Protected routes
    Route::middleware(['auth'])->group(function () {
        Route::get('/create', [PostController::class, 'create'])->name('posts.create');
        Route::post('/', [PostController::class, 'store'])->name('posts.store');
        Route::get('/{post}/edit', [PostController::class, 'edit'])->name('posts.edit');
        Route::put('/{post}', [PostController::class, 'update'])->name('posts.update');
        Route::delete('/{post}', [PostController::class, 'destroy'])->name('posts.destroy');
    });
});

// Dashboard (protected)
Route::middleware(['auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
});
