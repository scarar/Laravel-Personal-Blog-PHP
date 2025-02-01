@extends('layouts.app')

@section('content')
    <div class="bg-white rounded-lg shadow-md p-8">
        <h1 class="text-2xl font-bold mb-6">Edit Post</h1>

        <form action="{{ route('posts.update', $post) }}" method="POST" enctype="multipart/form-data">
            @csrf
            @method('PUT')

            <div class="mb-4">
                <label for="title" class="block text-gray-700 font-bold mb-2">Title</label>
                <input type="text" name="title" id="title" class="w-full px-3 py-2 border rounded-lg @error('title') border-red-500 @enderror" value="{{ old('title', $post->title) }}" required>
                @error('title')
                    <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="mb-4">
                <label for="content" class="block text-gray-700 font-bold mb-2">Content</label>
                <textarea name="content" id="content" rows="10" class="w-full px-3 py-2 border rounded-lg @error('content') border-red-500 @enderror" required>{{ old('content', $post->content) }}</textarea>
                @error('content')
                    <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="mb-6">
                <label for="featured_image" class="block text-gray-700 font-bold mb-2">Featured Image</label>
                @if ($post->featured_image)
                    <div class="mb-2">
                        <img src="{{ asset('storage/' . $post->featured_image) }}" alt="Current featured image" class="w-48 h-48 object-cover rounded">
                    </div>
                @endif
                <input type="file" name="featured_image" id="featured_image" class="w-full @error('featured_image') border-red-500 @enderror" accept="image/*">
                @error('featured_image')
                    <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="flex items-center">
                <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600">
                    Update Post
                </button>
                <a href="{{ route('posts.show', $post) }}" class="ml-4 text-gray-600 hover:text-gray-800">Cancel</a>
            </div>
        </form>
    </div>
@endsection