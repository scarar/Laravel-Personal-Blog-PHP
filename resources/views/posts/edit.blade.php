@extends('layouts.app')

@section('content')
<div class="space-y-6">
    <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold text-gray-900">Edit Post</h1>
        <a href="{{ route('posts.show', $post) }}" class="text-blue-600 hover:text-blue-800 flex items-center">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
            Back to Post
        </a>
    </div>

    <div class="bg-white shadow rounded-lg">
        <form action="{{ route('posts.update', $post) }}" method="POST" enctype="multipart/form-data" class="space-y-6 p-6">
            @csrf
            @method('PUT')

            <!-- Title -->
            <div>
                <label for="title" class="form-label">Title</label>
                <input type="text" 
                       name="title" 
                       id="title" 
                       class="form-input" 
                       value="{{ old('title', $post->title) }}" 
                       required>
                @error('title')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <!-- Excerpt -->
            <div>
                <label for="excerpt" class="form-label">Excerpt</label>
                <textarea name="excerpt" 
                          id="excerpt" 
                          class="form-input" 
                          rows="3">{{ old('excerpt', $post->excerpt) }}</textarea>
                @error('excerpt')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <!-- Content -->
            <div>
                <label for="content" class="form-label">Content</label>
                <textarea name="content" 
                          id="content" 
                          class="tinymce" 
                          rows="12">{{ old('content', $post->content) }}</textarea>
                @error('content')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <!-- Featured Image -->
            <div>
                <label for="featured_image" class="form-label">Featured Image</label>
                <input type="file" 
                       name="featured_image" 
                       id="featured_image" 
                       class="form-input" 
                       accept="image/*">
                @error('featured_image')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
                @if ($post->featured_image)
                    <div class="mt-2">
                        <img src="{{ asset('storage/' . $post->featured_image) }}" 
                             alt="Current featured image" 
                             class="max-w-xs rounded">
                    </div>
                @endif
                <img src="" alt="Preview" class="image-preview mt-2 hidden max-w-xs">
            </div>

            <!-- Status -->
            <div>
                <label for="status" class="form-label">Status</label>
                <select name="status" id="status" class="form-input">
                    <option value="draft" {{ old('status', $post->status) == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="published" {{ old('status', $post->status) == 'published' ? 'selected' : '' }}>Published</option>
                </select>
                @error('status')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <!-- Published At -->
            <div>
                <label for="published_at" class="form-label">Publish Date</label>
                <input type="datetime-local" 
                       name="published_at" 
                       id="published_at" 
                       class="form-input" 
                       value="{{ old('published_at', $post->published_at ? $post->published_at->format('Y-m-d\TH:i') : '') }}">
                @error('published_at')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <!-- Submit Button -->
            <div class="flex justify-end space-x-4">
                <a href="{{ route('posts.show', $post) }}" class="btn btn-secondary">
                    Cancel
                </a>
                <button type="submit" class="btn btn-primary">
                    Update Post
                </button>
            </div>
        </form>
    </div>
</div>
@endsection