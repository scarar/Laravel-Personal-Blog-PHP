@extends('layouts.app')

@section('content')
    <article class="bg-white rounded-lg shadow-md overflow-hidden">
        @if ($post->featured_image)
            <img src="{{ asset('storage/' . $post->featured_image) }}" alt="{{ $post->title }}" class="w-full h-96 object-cover">
        @endif
        
        <div class="p-8">
            <h1 class="text-4xl font-bold mb-4">{{ $post->title }}</h1>
            
            <div class="flex items-center text-gray-500 text-sm mb-8">
                <span>By {{ $post->user->name }}</span>
                <span class="mx-2">•</span>
                <span>{{ $post->created_at->format('F j, Y') }}</span>
            </div>

            <div class="prose max-w-none">
                {!! nl2br(e($post->content)) !!}
            </div>

            @can('update', $post)
                <div class="mt-8 flex space-x-4">
                    <a href="{{ route('posts.edit', $post) }}" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
                        Edit Post
                    </a>
                    
                    <form method="POST" action="{{ route('posts.destroy', $post) }}" class="inline">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600" onclick="return confirm('Are you sure you want to delete this post?')">
                            Delete Post
                        </button>
                    </form>
                </div>
            @endcan
        </div>
    </article>
@endsection