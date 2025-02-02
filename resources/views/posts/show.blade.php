@extends('layouts.app')

@section('content')
<article class="space-y-8">
    <!-- Post Header -->
    <header class="bg-white shadow rounded-lg p-6">
        <div class="max-w-4xl mx-auto">
            <div class="flex justify-between items-center mb-6">
                <a href="{{ route('posts.index') }}" class="text-blue-600 hover:text-blue-800 flex items-center">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
                    </svg>
                    Back to Posts
                </a>
                @auth
                    @if (auth()->user()->id === $post->user_id || auth()->user()->isAdmin())
                        <div class="flex space-x-2">
                            <a href="{{ route('posts.edit', $post) }}" class="btn btn-secondary">
                                Edit Post
                            </a>
                            <form action="{{ route('posts.destroy', $post) }}" method="POST" class="inline">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger" onclick="return confirm('Are you sure you want to delete this post?')">
                                    Delete Post
                                </button>
                            </form>
                        </div>
                    @endif
                @endauth
            </div>

            <h1 class="text-4xl font-bold text-gray-900 mb-4">{{ $post->title }}</h1>
            
            <div class="flex items-center text-gray-600">
                <span class="mr-4">By {{ $post->user->name }}</span>
                <span>{{ $post->created_at->format('F j, Y') }}</span>
            </div>
        </div>
    </header>

    <!-- Featured Image -->
    @if ($post->featured_image)
        <div class="bg-white shadow rounded-lg overflow-hidden">
            <img src="{{ asset('storage/' . $post->featured_image) }}" 
                 alt="{{ $post->title }}" 
                 class="w-full h-96 object-cover">
        </div>
    @endif

    <!-- Post Content -->
    <div class="bg-white shadow rounded-lg p-6">
        <div class="max-w-4xl mx-auto prose prose-lg">
            {!! $post->content !!}
        </div>
    </div>

    <!-- Post Footer -->
    <footer class="bg-white shadow rounded-lg p-6">
        <div class="max-w-4xl mx-auto flex justify-between items-center">
            <div class="text-sm text-gray-600">
                Last updated {{ $post->updated_at->diffForHumans() }}
            </div>
            <div class="flex space-x-4">
                <!-- Add social sharing buttons here if needed -->
            </div>
        </div>
    </footer>
</article>
@endsection